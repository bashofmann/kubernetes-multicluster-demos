#!/usr/bin/env bash

NODES=$(kubectl get nodes -o name)

for NODE in ${NODES}; do
    EXTERNAL_IP=$(kubectl get ${NODE} -o json | jq -r '.status.addresses[] | select(.type =="ExternalIP") | .address')
    kubectl annotate ${NODE} "kilo.squat.ai/force-external-ip=${EXTERNAL_IP}/16"
done
