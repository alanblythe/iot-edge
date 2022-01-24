#!/bin/sh

rootCert="azure-iot-test-only.root.ca.cert.pem"
deviceCert=""
deviceKey=""

# ======================= Install nested root CA =======================================
cp $rootCert /usr/local/share/ca-certificates/$rootCert.crt
update-ca-certificates
systemctl restart docker

# ======================= Copy device certs  =======================================
cert_dir="/etc/aziot/certificates"
mkdir -p $cert_dir
cp "$rootCert" "$cert_dir/$rootCert"
# cp "$device_id.full-chain.cert.pem" "$cert_dir/$device_id.full-chain.cert.pem"
# cp "$device_id.key.pem" "$cert_dir/$device_id.key.pem"



# # ======================= Install nested root CA =======================================
# cp iotedge_config_cli_root.pem /usr/local/share/ca-certificates/iotedge_config_cli_root.pem.crt
# update-ca-certificates
# systemctl restart docker

# # ======================= Copy device certs  =======================================
# cert_dir="/etc/aziot/certificates"
# mkdir -p $cert_dir
# cp "iotedge_config_cli_root.pem" "$cert_dir/iotedge_config_cli_root.pem"
# cp "$device_id.full-chain.cert.pem" "$cert_dir/$device_id.full-chain.cert.pem"
# cp "$device_id.key.pem" "$cert_dir/$device_id.key.pem"