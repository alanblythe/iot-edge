#!/bin/sh
gw=${1:-iotedge-gateway}
child1=${2:-iotedge-child1}
child2=${3:-iotedge-child2}
admin=${4:-ablythe}

scripts="scripts/install-certs.sh"
rootCert="iotedge-certs/certs/azure-iot-test-only.root.ca.cert.pem azure-iot-test-only.intermediate.cert.pem"
gwCaCerts="iotedge-certs/certs/iot-edge-device-ca-$gw-ca.cert.pem iotedge-certs/private/iot-edge-device-ca-$gw-ca.key.pem"
gwIdentCerts="iotedge-certs/certs/iot-edge-device-identity-$gw-primary.cert.pem iotedge-certs/private/iot-edge-device-identity-$gw-primary.key.pem iotedge-certs/certs/iot-edge-device-identity-$gw-secondary.cert.pem iotedge-certs/private/iot-edge-device-identity-$gw-secondary.key.pem"
child1IdentCerts="iotedge-certs/certs/iot-edge-device-identity-$child1-primary.cert.pem iotedge-certs/private/iot-edge-device-identity-$child1-primary.key.pem iotedge-certs/certs/iot-edge-device-identity-$child1-secondary.cert.pem iotedge-certs/private/iot-edge-device-identity-$child1-secondary.key.pem"
child2IdentCerts="iotedge-certs/certs/iot-edge-device-identity-$child2-primary.cert.pem iotedge-certs/private/iot-edge-device-identity-$child2-primary.key.pem iotedge-certs/certs/iot-edge-device-identity-$child2-secondary.cert.pem iotedge-certs/private/iot-edge-device-identity-$child2-secondary.key.pem"

region=eastus
domain=cloudapp.azure.com
gwDnsName=ablythe-edge-test-gateway
child1DnsName=ablythe-edge-test-child1
# child2DnsName=ablythe-edge-test-child2

scp $rootCert $scripts $gwCaCerts $gwIdentCerts ${admin}@${gwDnsName}.${region}.${domain}:~
scp $rootCert $scripts $gwCaCerts $child1IdentCerts ${admin}@${child1DnsName}.${region}.${domain}:~
# scp $rootCert $scripts $child2IdentCerts ${admin}@${child2DnsName}.${region}.${domain}:~

ssh ${admin}@${gwDnsName}.${region}.${domain} sudo bash install-certs.sh
ssh ${admin}@${child1DnsName}.${region}.${domain} sudo bash install-certs.sh
# ssh ${admin}@${child2DnsName}.${region}.${domain} sudo bash install-certs.sh
