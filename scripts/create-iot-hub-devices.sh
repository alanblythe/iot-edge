#!/bin/sh

az iot hub certificate create --hub-name cayers-edge-dev --name RootCA --path iotedge-certs/certs/azure-iot-test-only.root.ca.cert.pem --verified

pri=$(get_fingerprint ./iotedge-certs/certs/iot-edge-device-identity-$1-primary.cert.pem)
sec=$(get_fingerprint ./iotedge-certs/certs/iot-edge-device-identity-$1-secondary.cert.pem)
az iot hub device-identity create -n cayers-edge-dev -d $1 --ee --am x509_thumbprint --ptp "$pri" --stp "$sec"

pri=$(get_fingerprint ./iotedge-certs/certs/iot-edge-device-identity-$2-primary.cert.pem)
sec=$(get_fingerprint ./iotedge-certs/certs/iot-edge-device-identity-$2-secondary.cert.pem)
az iot hub device-identity create -n cayers-edge-dev -d $2 --ee --am x509_thumbprint --ptp "$pri" --stp "$sec"

