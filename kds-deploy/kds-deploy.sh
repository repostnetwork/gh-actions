#!/bin/bash

if [ -z "$LOGICAL_NAME" ]
then
      echo "The environment variable LOGICAL_NAME must be defined"
      exit 1
fi


echo -e "Building Docker..."
docker build -t $LOGICAL_NAME --build-arg ENV=$ENV --build-arg TYPE=$TYPE . || exit 1

echo -e "Creating KDS stream"
aws kinesis create-stream --stream-name $LOGICAL_NAME --shard-count 4 || true

echo -e "Creating EC cluster"
aws elasticache create-cache-cluster --cache-cluster-id "${LOGICAL_NAME}-kds-dedup" --engine memcached --cache-node-type cache.m5.large --num-cache-nodes 1 || true

echo -e "Installing jq while EC cluster creates"
echo "Y" | sudo apt-get install jq

echo -e "Getting EC cluster config endpoint"
CONFIG_ENDPOINT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id "${LOGICAL_NAME}-kds-dedup" \
    --show-cache-node-info | jq '.CacheClusters[0].ConfigurationEndpoint.Address')

echo -e "Saving EC cluster config endpoint"
KEYSTORE_PATH="${LOGICAL_NAME}/ECConfigurationEndpoint"
JSON_PARAMS='{'
JSON_PARAMS+='"Name": "'${KEYSTORE_PATH}'",'
JSON_PARAMS+='"Value": "'${CONFIG_ENDPOINT}'",'
JSON_PARAMS+='"Type": "String",'
JSON_PARAMS+='"Overwrite": true'
JSON_PARAMS+='}'
aws ssm put-parameter \
     --cli-input-json "${JSON_PARAMS}"