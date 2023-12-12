#!/usr/bin/python3
from logconfig import logger
from configuration import config
from InstanceMetadata import InstanceMetadata
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient
from msrestazure.azure_active_directory import MSIAuthentication
from bearer_token import BearerAuth

import requests, json, os, time, sys, socket

# Initializing InstanceMetadata
metadata = InstanceMetadata().populate()
isPendingDelete = metadata.isPendingDelete()

host_name = socket.gethostname()
host_ip = socket.gethostbyname(host_name)
timeSleep = 10

def delete_vmss_instance():
    ##MSI based authentication
    logger.info("Entry Point of delete_vmss_instance")
    credentials       = MSIAuthentication()
    metadata          = InstanceMetadata().populate()
    
    subscription_id   = metadata.subscriptionId
    #resource_client   = ResourceManagementClient(credentials, subscription_id)
    compute_client    = ComputeManagementClient(credentials, subscription_id)
    #network_client    = NetworkManagementClient(credentials, subscription_id)

    resourceGroupName = metadata.resourceGroupName
    vmScaleSetName    = metadata.vmScaleSetName
    vmname            = metadata.name
    logger.info("metadata.name : " + vmname)
    vm_id = vmname.split("_")
    convertedInt_vm_id = int(vm_id[1])
    
    #host_name         = socket.gethostname()
    #vmid              = hostname_to_vmid(host_name)
    compute_client.virtual_machine_scale_set_vms.delete(resourceGroupName, vmScaleSetName, convertedInt_vm_id)

def hostname_to_vmid(hostname):
    # get last 6 characters and remove leading zeroes
    hexatrig = hostname[-6:].lstrip('0')
    multiplier = 1
    vmid = 0
    # reverse string and process each char
    for x in hexatrig[::-1]:
        if x.isdigit():
            vmid += int(x) * multiplier
        else:
            # convert letter to corresponding integer
            vmid += (ord(x) - 55) * multiplier
        multiplier *= 36
    return vmid

# Check the value of Platform.PendingDeletionTime tag of IMDS
if (isPendingDelete == False):
    logger.info('exit : ' + str(isPendingDelete))
    sys.exit(1)

# Get App GW Backend status check URL and App GW name
appGatewayUrl = config.get('appgw', 'appgw_behealth_url')
appGateway = config.get('appgw', 'appgw_name')

formatted_url = appGatewayUrl.format(subscriptionId = metadata.subscriptionId, \
                resourceGroupName = metadata.resourceGroupName,\
                appGatewayName = appGateway)

# Getting App GW backend health URI
try:
    r = requests.post(formatted_url, headers = {}, auth=BearerAuth(metadata.access_token))
except requests.exceptions.RequestException as e:
    logger.info("error : " + str(e))
    sys.exit(1)

# Waiting for another api to check the result.
time.sleep(timeSleep)
try:
    resp = requests.get(r.headers["Location"], auth=BearerAuth(metadata.access_token))
except requests.exceptions.RequestException as e:
    logger.info("error : " + str(e))
    sys.exit(1)

# Delete VMSS instance
if (resp.status_code == 200):
    pools = resp.json()["backendAddressPools"]
    for pool in pools:
        settings = pool["backendHttpSettingsCollection"]
        for setting in settings:
            servers = setting["servers"]
            for server in servers:
                if (host_ip == server["address"]):
                    health = server["health"]
                    logger.info(host_name + " is " + health)
                    if (health == "Unhealthy"):
                        #check copying log and stopping custom metric
                        logger.info("Check copying logs and stopping custom metric.")
                        #delete vmss instance
                        logger.info("Delete " + host_name)
                        delete_vmss_instance()

