#!/bin/sh

rootCert="azure-iot-test-only.root.ca.cert.pem"
deviceCert="iot-*.cert.pem"
deviceKey="iot*.key.pem"

# ======================= Install nested root CA =======================================
cp $rootCert /usr/local/share/ca-certificates/$rootCert.crt
update-ca-certificates

# ======================= Copy device certs  =======================================
cd ~
cert_dir="/etc/aziot/certificates"
mkdir -p $cert_dir
cp $rootCert $cert_dir
cp $deviceCert $cert_dir
cp $deviceKey $cert_dir

sudo iotedge restart
