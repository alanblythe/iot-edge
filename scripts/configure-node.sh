#!/bin/sh

type=${1:-child}
deviceId=${2:-iotedge-child}
gateway=${3:-iotedge-gateway}
hubDNS=${4:-cayers-edge-test-dev.azure-devices.net}

case $type in

  child)
    cat child.toml  | sed s/DEVICEID/${deviceId}/g | sed s/GATEWAYID/${gateway}/g | sed s/HUB_DNSNAME/${hubDNS}/g  > /etc/aziot/config.toml
    ;;

  gateway)
    cat gateway.toml  | sed s/DEVICEID/${deviceId}/g | sed s/GATEWAYID/${gateway}/g | sed s/HUB_DNSNAME/${hubDNS}/g  > /etc/aziot/config.toml
    ;;

  *)
    echo -n "unknown"
    ;;
esac

sudo iotedge config apply

