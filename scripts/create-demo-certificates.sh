#!/bin/sh

git clone https://github.com/Azure/iotedge.git
mkdir iotedge-certs
cd iotedge-certs
cp ../iotedge/tools/CACertificates/*.cnf .
cp ../iotedge/tools/CACertificates/certGen.sh .
./certGen.sh create_root_and_intermediate
./certGen.sh create_edge_device_identity_certificate "$1-primary"
./certGen.sh create_edge_device_identity_certificate "$1-secondary"
./certGen.sh create_edge_device_ca_certificate "$1-ca"
./certGen.sh create_edge_device_identity_certificate "$2-primary"
./certGen.sh create_edge_device_identity_certificate "$2-secondary"

get_fingerprint () {
    openssl x509 -in $1 -fingerprint -noout | cut -d= -f2 | sed -e 's/://g'
}
