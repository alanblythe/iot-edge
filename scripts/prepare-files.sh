#!/bin/sh

device=${1:-iotedge-gateway}
admin=${2:-cayers}

scp iotedge-certs/certs/azure-iot-test-only.root.ca.cert.pem ${admin}@${device}:~
