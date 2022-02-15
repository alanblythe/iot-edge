#!/bin/sh

device=${1:-iotedge-gateway}
admin=${2:-cayers}

ls iotedge-certs/certs/iot-edge-device-identity-iotedge-gateway*
for i in `ls iotedge-certs/certs/iot-edge-device-identity-${device}*`; do mv "$i" "`echo $i | sed s/${device}/${device}-primary/g`"; done
ls iotedge-certs/certs/iot-edge-device-identity-iotedge-gateway*
