#!/usr/bin/python3

# simple HTTP server which run a simple page for health probe

from flask import Flask, render_template, request, redirect, url_for 
from flask_api import status

from logconfig import logger
from configuration import config
from InstanceMetadata import InstanceMetadata
import requests, json, os

hostname = '0.0.0.0'
hostport = 9000
instance_status = status.HTTP_200_OK

def checkInstanceHealth(metadata):
    global instance_status

    if instance_status == status.HTTP_200_OK and metadata.isPendingDelete():
        instance_status = status.HTTP_410_GONE # HTTP Status Code 410 (Gone)

    status_string = 'Healthy'
    if instance_status == status.HTTP_410_GONE:
        status_string = 'Gone'

    return status_string, instance_status

app = Flask(__name__)

###### Route when nothing is specified in the url######  
@app.route('/') 
def index():
    metadata = InstanceMetadata().populate()
    return render_template('index.html', vmId = metadata.vmId, name = metadata.name, location = metadata.location, privateIp = metadata.privateIp, subscriptionId = metadata.subscriptionId, resourceGroupName = metadata.resourceGroupName, vmScaleSetName = metadata.vmScaleSetName, tagList = metadata.tagsList), status.HTTP_200_OK

@app.route('/health')
def isHealthy():
    metadata = InstanceMetadata().populate()
    return checkInstanceHealth(metadata)

if __name__ == '__main__':
    app.run(debug=False, host=hostname, port=hostport)
