#!/usr/bin/env bash

export IMAGE=$1
docker-compose -f docker-compose.yaml up -d
echo "docker-compose.yaml file has been deployed successfully."