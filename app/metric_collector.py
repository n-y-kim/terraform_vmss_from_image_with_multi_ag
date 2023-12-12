#!/usr/bin/python3

import psutil, requests, datetime, json
from logconfig import logger
from configuration import config
from vminstance import VMInstance
from bearer_token import BearerAuth

def collect_metrics():
    global cpu_percent
    logger.info("Collecting Metrics .....")

    cpu_percent = psutil.cpu_percent()
    logger.info("Current CPU utilization is %s percent.  " % cpu_percent)

def post_metrics():
    global cpu_percent
    logger.info("Posting Custom metrics.....")

    metric_post_url = config.get('monitor', 'metric_post_url')

    formatted_url = metric_post_url.format(location = vmInstance.location, 
                    subscriptionId = vmInstance.subscriptionId, \
                    resourceGroupName = vmInstance.resourceGroupName,\
                    resourceName = vmInstance.name)

    data = getMetricPostData(cpu_percent)
    logger.info("Data: " + json.dumps(data))

    headers = config.get('monitor', 'metric_headers');
    headers = json.loads(headers)
    headers['Content-Length'] = str(len(data))
    headers['Authorization'] = "Bearer " + vmInstance.access_token

    #formatted_headers = headers.format(clength = len(data))
    #formatted_headers['Authorization'] = "Bearer " + vmInstance.access_token
    logger.info("headers: " + json.dumps(headers))


    requests.post(formatted_url, json=data, headers=headers)



def getMetricPostData(metric_data):
    data = {
        'time': datetime.datetime.now().isoformat(),
        'data':{
            'baseData':{
                'metric': 'CPU Utilization',
                'namespace': 'SamsungMetrics',
                'dimNames':[
                    "CPU Percentage"
                ],
                'series':[
                    {
                        'dimValue':[
                            metric_data
                        ]
                    }
                ]
            }
        }
    }
        
    return data


vmInstance = VMInstance().populate()
collect_metrics()
post_metrics()