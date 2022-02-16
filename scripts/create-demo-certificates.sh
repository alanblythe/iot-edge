#!/bin/sh
echo 

base=${1:-iotedge-}
gw=${2:-gateway}
child1=${3:-child1}
child2=${4:-child2}

generateKeys() {
    ./certGen.sh create_edge_device_identity_certificate "$1"
    for i in `ls certs/iot-edge-device-identity-$1* | grep -v primary | grep -v secondary`; do mv "$i" "`echo $i | sed s/$1/$1-primary/g`"; done
    for i in `ls private/iot-edge-device-identity-$1* | grep -v primary | grep -v secondary`; do mv "$i" "`echo $i | sed s/$1/$1-primary/g`"; done
    ./certGen.sh create_edge_device_identity_certificate "$1"
    for i in `ls certs/iot-edge-device-identity-$1* | grep -v primary | grep -v secondary`; do mv "$i" "`echo $i | sed s/$1/$1-secondary/g`"; done
    for i in `ls private/iot-edge-device-identity-$1* | grep -v primary | grep -v secondary`; do mv "$i" "`echo $i | sed s/$1/$1-secondary/g`"; done
}

git clone https://github.com/Azure/iotedge.git
mkdir iotedge-certs
cd iotedge-certs
cp ../iotedge/tools/CACertificates/*.cnf .
cp ../iotedge/tools/CACertificates/certGen.sh .
./certGen.sh create_root_and_intermediate
generateKeys "$base$gw"
./certGen.sh create_edge_device_ca_certificate "$base$gw-ca"

generateKeys "$base$child1"
generateKeys "$base$child2"
