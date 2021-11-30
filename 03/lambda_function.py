import boto3

def lambda_handler(event, context):

  regionid = event['region']
  ec2 = boto3.resource("ec2", region_name=regionid)
  available_volumes = ec2.volumes.filter(
    Filters=[{'Name': 'status', 'Values': ['available']}]
  )

  for volume in available_volumes:
    print volume.id
    volume.delete()
  return "Completed"
