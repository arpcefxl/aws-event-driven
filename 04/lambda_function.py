import boto3
import json
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(event)

    #fun translation of event into something Python can use
    event_dict=json.dumps(event)
    event_json=json.loads(event_dict)
    detail=event_json['detail']
    logger.info("Detail =%s", detail)

    #extract Instance ID from the event
    instance_id=detail['instance-id']

    logger.info("Instance ID =%s", instance_id)

    #get the ec2 object
    client = boto3.client('ec2')
    newinstanceraw = client.describe_instances(
        Filters=[
            {'Name': 'instance-id', 'Values': [instance_id]}
            ]
        )
    #fun translation of instance object data into something Python can use
    newinstancedict = json.dumps(newinstanceraw, default=str)
    newinstance = json.loads(newinstancedict)
    
    #extract secgroup ID list for the instance
    sgids = [item.get('GroupId') for item in newinstance['Reservations'][0]['Instances'][0]['NetworkInterfaces'][0]['Groups']]
    logger.info("SGIDs=%s", sgids)
    
    #extract the VPC ID for the instance
    vpcid = newinstance['Reservations'][0]['Instances'][0]['VpcId']
    logger.info("VPCID=%s", vpcid)
    
    #extract the VPC-specific secgroup ID for VPN access
    ssm = boto3.client('ssm')
    sgidparameter = ssm.get_parameter(Name=vpcid)
    vpnsgid = sgidparameter['Parameter']['Value']
    logger.info("VPN secgroup id = %s", vpnsgid)
    
    #append the vpn sgid to the list of secgroups
    sgids.append(vpnsgid)
    logger.info("SGIDs=%s", sgids)

    #update the instance attributes to include new secgroup
    #this is an idempotent action, so if the secgroup already attached, no error
    secgroupadd = client.modify_instance_attribute(
        InstanceId=instance_id,
        Groups=sgids
        )
    logger.info("output of secgroupadd=%s", secgroupadd)

