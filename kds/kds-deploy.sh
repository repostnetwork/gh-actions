#!/bin/bash

if [ -z "$LOGICAL_NAME" ]
then
      echo "The environment variable LOGICAL_NAME must be defined"
      exit 1
fi

if [ -z "$SHARD_COUNT" ]
then
      echo "No shard count specified, using the default of 4"
      SHARD_COUNT=4
fi

#echo -e "Building Docker..."
#docker build -t $LOGICAL_NAME --build-arg ENV=$ENV --build-arg TYPE=$TYPE . || exit 1

echo -e "Creating KDS stream"
aws kinesis create-stream --stream-name $LOGICAL_NAME --shard-count $SHARD_COUNT || true

NEW_CLUSTER=true
echo -e "Creating EC cluster"
aws elasticache create-cache-cluster --cache-cluster-id "${LOGICAL_NAME}-kds-dedup" --engine memcached --cache-node-type cache.m5.large --num-cache-nodes 1 || NEW_CLUSTER=false

if [ "$NEW_CLUSTER" = true ]; then
  echo -e "Installing jq"
  echo "Y" | sudo apt-get install jq

  echo -e "Getting EC cluster config endpoint"
  CONFIG_ENDPOINT=$(aws elasticache describe-cache-clusters \
      --cache-cluster-id "${LOGICAL_NAME}-kds-dedup" \
      --show-cache-node-info | jq '.CacheClusters[0].ConfigurationEndpoint.Address')

  end=$((SECONDS+300))
  while [[ $SECONDS -lt $end  && (-z "${CONFIG_ENDPOINT}" || "${CONFIG_ENDPOINT}" = "null") ]]; do
      echo "cluster not provisioned, retrying in 15s"
      sleep 15
      CONFIG_ENDPOINT=$(aws elasticache describe-cache-clusters \
        --cache-cluster-id "${LOGICAL_NAME}-kds-dedup" \
        --show-cache-node-info | jq '.CacheClusters[0].ConfigurationEndpoint.Address')
      :
  done

  echo -e "Saving EC cluster config endpoint"
  KEYSTORE_PATH="/${LOGICAL_NAME}/ECConfigurationEndpoint"
  JSON_PARAMS='{'
  JSON_PARAMS+='"Name": "'${KEYSTORE_PATH}'",'
  JSON_PARAMS+='"Value": '${CONFIG_ENDPOINT}','
  JSON_PARAMS+='"Type": "String",'
  JSON_PARAMS+='"Overwrite": true'
  JSON_PARAMS+='}'
  aws ssm put-parameter \
       --cli-input-json "${JSON_PARAMS}"
fi