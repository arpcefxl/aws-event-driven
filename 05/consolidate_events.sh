#!/bin/bash
#Consolidates EventBridge events into a single region
CENTRALREGION=$1
ACCTID=$2
PROFILE=$3
EVENTBUSARN="arn:aws:events:${CENTRALREGION}:${ACCTID}:event-bus/default"

#Create an IAM role required for cross-region event target
ROLEARN=`aws --region us-east-1 --output text --profile $PROFILE iam create-role --role-name EventBusConsolidationRole --assume-role-policy-document file://role_trust_policy.json --query Role.Arn`
echo "role arn is $ROLEARN"

#Substitute the variable in the template permission policy with the correct event bus ARN
sed "s|EVENTBUSARN|${EVENTBUSARN}|g" role_permission_template.json > role_permission_policy.json

#Create an IAM policy from the updated permission policy
IAMPOLICYARN=`aws --region us-east-1 --output text --profile $PROFILE iam create-policy --policy-name EventBusConsolidationPolicy --policy-document file://role_permission_policy.json --query Policy.Arn`
echo "iam policy ARN is $IAMPOLICYARN"
#Attach the new IAM policy to the role
aws --region us-east-1 --output text --profile $PROFILE iam attach-role-policy --role-name EventBusConsolidationRole --policy-arn $IAMPOLICYARN


#Create the EventBridge rule which forwards all events to the central region using the newly created IAM role

REGIONS=`aws --region us-east-1 --output text --profile $PROFILE ec2 describe-regions --query Regions[].RegionName |tr -s '\t' '\n'`
for i in $REGIONS; do
if [[ $i != $CENTRALREGION ]]; then
  echo "Creating rule in region $i"
  aws --profile $PROFILE events --region $i put-rule --name "EventConsolidation" --event-pattern "{\"account\":[\"${ACCTID}\"]}"
  aws --profile $PROFILE events --region $i put-targets --rule "EventConsolidation" --targets "Id"="1","Arn"="${EVENTBUSARN}","RoleArn"="${ROLEARN}"
fi
done
