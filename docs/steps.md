# Steps

- az login
- az account set -s "SUBID"
- az group create -l eastus -n rg-iot
- az deployment group create -g rg-iot --template-file deploy/main.bicep --parameters deploy/main.parameters.json
- az vm run-command invoke -g rg-iot -n ablythe-edge-test-gateway --command-id RunShellScript --scripts '@scripts/install-iot-edge.sh'
- az vm run-command invoke -g rg-iot -n cayers-edge-test-child1 --command-id RunShellScript --scripts '@scripts/install-iot-edge.sh'
- az vm run-command invoke -g rg-iot -n cayers-edge-test-child2 --command-id RunShellScript --scripts '@scripts/install-iot-edge.sh'
- ./scripts/create-demo-certificates.sh
- ./scripts/create-iot-hub-devices.sh
- ./scripts/upload-files.sh
- ssh ablythe@ablythe-edge-test-gateway.eastus.cloudapp.azure.com sudo reboot
- ssh ablythe@ablythe-edge-test-child1.eastus.cloudapp.azure.com sudo reboot
# - ssh cayers@cayers-edge-test-child2.eastus.cloudapp.azure.com sudo reboot
- 

# TODO set the child device
# TODO change the child to a leaf device, its an edge device right now
# TODO add a DNS private zone

# TODO add a step for installing Java on the child for testing

# https://github.com/Azure/azure-iot-sdk-java/tree/main/device/iot-device-samples/send-event
# shows using gatewayhostname in the connection string

openssl s_client -showcerts -connect ablythe-edge-test-gateway:8883 >cert.pem </dev/null

sudo nano /etc/aziot/config.toml

# run jar
HostName=myiothub.azure-devices.net;DeviceId=***yourdeivceid***;SharedAccessKey=xxxyyyzzz;GatewayHostName= YourGatewayHostname.ca
HostName=ablythe-edge-test-gateway;DeviceId=***yourdeivceid***;x509=true

HostName=myGatewayDevice;DeviceId=***yourdeivceid***;SharedAccessKey=xxxyyyzzz

# how to run the connection test
java -jar iot-edge.jar "iotedge-child1" "mqtt" "HostName=ablythe-edge-test-dev.azure-devices.net;DeviceId=iotedge-child1;x509=true;GatewayHostName=ablythe-edge-test-gateway"

java -jar iot-edge.jar "iotedge-child1" "mqtt" "HostName=ablythe-edge-test-dev.azure-devices.net;DeviceId=***yourdeivceid***;x509=true;GatewayHostName=ablythe-edge-test-gateway"

sudo iotedge logs edgeHub


