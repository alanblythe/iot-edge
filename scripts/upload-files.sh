#!/bin/sh
gw=${1:-iotedge-gateway}
child1=${2:-iotedge-child1}
child2=${3:-iotedge-child2}
admin=${4:-cayers}

scripts="scripts/install-certs.sh scripts/getFingerprint.sh"
configs="scripts/gateway.toml scripts/child.toml"
rootCert="iotedge-certs/certs/azure-iot-test-only.root.ca.cert.pem"
gwCaCerts="iotedge-certs/certs/iot-edge-device-ca-$gw-ca.cert.pem iotedge-certs/certs/iot-edge-device-ca-$gw-ca.cert.pfx iotedge-certs/certs/iot-edge-device-ca-$gw-ca-full-chain.cert.pem iotedge-certs/private/iot-edge-device-ca-$gw-ca.key.pem"
gwIdentCerts="iotedge-certs/certs/iot-edge-device-identity-$gw-primary.cert.pem iotedge-certs/certs/iot-edge-device-identity-$gw-primary.cert.pfx iotedge-certs/certs/iot-edge-device-identity-$gw-primary-full-chain.cert.pem iotedge-certs/certs/iot-edge-device-identity-$gw-secondary.cert.pem iotedge-certs/certs/iot-edge-device-identity-$gw-secondary.cert.pfx iotedge-certs/certs/iot-edge-device-identity-$gw-secondary-full-chain.cert.pem iotedge-certs/private/iot-edge-device-identity-$gw-primary.key.pem iotedge-certs/private/iot-edge-device-identity-$gw-secondary.key.pem"
child1IdentCerts="iotedge-certs/certs/iot-edge-device-identity-$child1-primary.cert.pem iotedge-certs/certs/iot-edge-device-identity-$child1-primary.cert.pfx iotedge-certs/certs/iot-edge-device-identity-$child1-primary-full-chain.cert.pem iotedge-certs/private/iot-edge-device-identity-$child1-primary.key.pem iotedge-certs/private/iot-edge-device-identity-$child1-secondary.key.pem"
child2IdentCerts="iotedge-certs/certs/iot-edge-device-identity-$child2-primary.cert.pem iotedge-certs/certs/iot-edge-device-identity-$child2-primary.cert.pfx iotedge-certs/certs/iot-edge-device-identity-$child2-primary-full-chain.cert.pem iotedge-certs/private/iot-edge-device-identity-$child2-primary.key.pem iotedge-certs/private/iot-edge-device-identity-$child2-secondary.key.pem"

region=eastus
domain=cloudapp.azure.com
gwDnsName=cayers-edge-test-gateway
child1DnsName=cayers-edge-test-child1
child2DnsName=cayers-edge-test-child2

scp $rootCert $scripts $configs $gwCaCerts $gwIdentCerts ${admin}@${gwDnsName}.${region}.${domain}:~
scp $rootCert $scripts $configs $child1IdentCerts ${admin}@${child1DnsName}.${region}.${domain}:~
scp $rootCert $scripts $configs $child2IdentCerts ${admin}@${child2DnsName}.${region}.${domain}:~

ssh ${admin}@${gwDnsName}.${region}.${domain} sudo bash install-certs.sh
ssh ${admin}@${child1DnsName}.${region}.${domain} sudo bash install-certs.sh
ssh ${admin}@${child2DnsName}.${region}.${domain} sudo bash install-certs.sh
