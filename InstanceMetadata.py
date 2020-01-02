from configuration import config
from logconfig import logger
import requests, json

class InstanceMetadata:
    '''This is the current VM Instance'''

    def __str__(self):
        return """
                VM Instance Metadata:
                     Id - {vmId}
                     Name - {name}
                     PrivateIp - {privateIp}
                     location - {location}
                     SubscriptionId - {subscriptionId}
                     ResourceGroupName - {resourceGroupName}
                     VMScaleSetName - {vmScaleSetName}
                     TagsList - {tagsList}
                     Access-Token - {access_token}
                """.format(
                    vmId = self.vmId,
                    name = self.name,
                    location = self.location,
                    privateIp = self.privateIp,
                    subscriptionId = self.subscriptionId,
                    resourceGroupName = self.resourceGroupName,
                    vmScaleSetName = self.vmScaleSetName,
                    tagsList = self.tagsList,
                    access_token = self.access_token
                )


    """
    This loads the instance info which can be used at other places for 
    calling diffrent Rest Endpoints
    """
    def populate(self):
        logger.info("Populating Current VM instance ....")
        try:
            imds_url = config.get('imds', 'imds_url')
            response = requests.get(imds_url, headers={"Metadata":"true"})
            response_txt = json.loads(response.text)

            #populate required instance variables
            self.vmId = response_txt['vmId']
            self.name = response_txt['name']
            self.location = response_txt['location']
            self.subscriptionId = response_txt['subscriptionId']
            self.vmScaleSetName = response_txt['vmScaleSetName']
            self.resourceGroupName = response_txt['resourceGroupName']
            self.tagsList = response_txt['tagsList']

            # obtain private ip address of instnace
            privateip_url = config.get('imds', 'privateip_url')
            response = requests.get(privateip_url, headers={"Metadata":"true"})
            self.privateIp = response.text

            #populate access_token
            self.access_token = ''
            accesstoken_url = config.get('imds', 'accesstoken_url')

            access_token_response = requests.get(accesstoken_url, headers={"Metadata":"true"})
            access_token_text = json.loads(access_token_response.text)
            self.access_token = access_token_text['access_token']

            logger.info("Returning populated VMInstance")
        except:
            logger.error("Error populating vm instance")

        return self

    """
    Check if the vm needs to be deleted
    """
    def isPendingDelete(self):
        deleteTag = config.get('imds', 'pending_delete_tag')
        pendingDeleteState = False
        
        for tag in self.tagsList:
            for k, v in tag.items():
                if( k == 'name' and v == deleteTag):
                    pendingDeleteState = True
        
        if pendingDeleteState:
            return True
        else:
            return False

