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
