#!/bin/sh

hub=${1:-ablythe-edge-test-dev}
base=${2:-iotedge-}
gw=${3:-gateway}
child1=${4:-child1}
child2=${5:-child2}

az iot hub certificate create --hub-name $hub --name RootCA --path iotedge-certs/certs/azure-iot-test-only.root.ca.cert.pem --verified

pri=$(./scripts/getFingerprint.sh ./iotedge-certs/certs/iot-edge-device-identity-$base$gw-primary.cert.pem)
sec=$(./scripts/getFingerprint.sh ./iotedge-certs/certs/iot-edge-device-identity-$base$gw-secondary.cert.pem)
az iot hub device-identity create -n $hub -d $base$gw --ee --am x509_thumbprint --ptp "$pri" --stp "$sec"

pri=$(./scripts/getFingerprint.sh ./iotedge-certs/certs/iot-edge-device-identity-$base$child1-primary.cert.pem)
sec=$(./scripts/getFingerprint.sh ./iotedge-certs/certs/iot-edge-device-identity-$base$child1-secondary.cert.pem)
az iot hub device-identity create -n $hub -d $base$child1 --am x509_thumbprint --ptp "$pri" --stp "$sec"

az iot hub device-identity children add -d $base$gw --child-list $base$child1 -n $hub

# pri=$(./scripts/getFingerprint.sh ./iotedge-certs/certs/iot-edge-device-identity-$base$child2-primary.cert.pem)
# sec=$(./scripts/getFingerprint.sh ./iotedge-certs/certs/iot-edge-device-identity-$base$child2-secondary.cert.pem)
# az iot hub device-identity create -n $hub -d $base$child2 --ee --am x509_thumbprint --ptp "$pri" --stp "$sec"

