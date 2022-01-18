#!/bin/bash
#Consolidates EventBridge events into a single region
CENTRALREGION=$1
ACCTID=$2
PROFILE=$3
EVENTBUSARN="arn:aws:events:${CENTRALREGION}:${ACCTID}:event-bus/default"

#Create an IAM role required for cross-region event target
#ROLEARN=`aws iam create-role --role-name EventBusConsolidationRole --assume-role-policy-document file://role_trust_policy.json --query Role.Arn`

#Substitute the variable in the template permission policy with the correct event bus ARN
#sed "s|EVENTBUSARN|${EVENTBUSARN}|g" role_permission_template.json > role_permission_policy.json

#Create an IAM policy from the updated permission policy
#IAMPOLICYARN=`aws iam create-policy --policy-name EventBusConsolidationPolicy --policy-document file://role_permission_policy.json --query Policy.Arn`

#Attach the new IAM policy to the role
#aws iam attach-role-policy --role-name EventBusConsolidationRole --policy-arn $IAMPOLICYARN


#Create the EventBridge rule which forwards all events to the central region using the newly created IAM role

REGIONS=`aws ec2 describe-regions --output text --query Regions[].RegionName |tr -s '\t' '\n'`
for i in $REGIONS; do
if [[ $i != $CENTRALREGION ]]; then
  echo "Deleting rule in region $i"
  aws --profile $PROFILE events --region $i remove-targets --rule "EventConsolidation" --id 1
  aws --profile $PROFILE events --region $i delete-rule --name "EventConsolidation" 
fi
done
