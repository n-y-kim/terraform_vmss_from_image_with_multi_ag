from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient
from msrestazure.azure_active_directory import MSIAuthentication
from InstanceMetadata import InstanceMetadata
import socket

def delete_vmss_instance():
    ##MSI based authentication
    credentials       = MSIAuthentication()
    vmInstance        = InstanceMetadata().populate()
    
    subscription_id   = vmInstance.subscriptionId
    #resource_client   = ResourceManagementClient(credentials, subscription_id)
    compute_client    = ComputeManagementClient(credentials, subscription_id)
    #network_client    = NetworkManagementClient(credentials, subscription_id)

    resourceGroupName = vmInstance.resourceGroupName
    vmScaleSetName    = vmInstance.vmScaleSetName
    vmname            = vmInstance.name
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

if __name__ == '__main__':
    delete_vmss_instance()