#!/bin/sh
echo 

base=${1:-iotedge-}
gw=${2:-gateway}
child1=${3:-child1}
child2=${4:-child2}

git clone https://github.com/Azure/iotedge.git
mkdir iotedge-certs
cd iotedge-certs
cp ../iotedge/tools/CACertificates/*.cnf .
cp ../iotedge/tools/CACertificates/certGen.sh .
./certGen.sh create_root_and_intermediate
./certGen.sh create_edge_device_identity_certificate "$base$gw-primary"
./certGen.sh create_edge_device_identity_certificate "$base$gw-secondary"
./certGen.sh create_edge_device_ca_certificate "$base$gw-ca"
./certGen.sh create_edge_device_identity_certificate "$base$child1-primary"
./certGen.sh create_edge_device_identity_certificate "$base$child1-secondary"
#./certGen.sh create_edge_device_identity_certificate "$base$child2-primary"
#./certGen.sh create_edge_device_identity_certificate "$base$child2-secondary"

get_fingerprint () {
    openssl x509 -in $1 -fingerprint -noout | cut -d= -f2 | sed -e 's/://g'
}
