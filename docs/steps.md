# Steps

- az login
- az account set -s "SUBID"
- az group create -l eastus -n rg-iot
- az deployment group create -g rg-iot --template-file deploy/main.bicep --parameters deploy/main.parameters.json
- az vm run-command invoke -g rg-iot -n cayers-edge-test-gateway --command-id RunShellScript --scripts '@scripts/install-iot-edge.sh'
- az vm run-command invoke -g rg-iot -n cayers-edge-test-child1 --command-id RunShellScript --scripts '@scripts/install-iot-edge.sh'
- az vm run-command invoke -g rg-iot -n cayers-edge-test-child2 --command-id RunShellScript --scripts '@scripts/install-iot-edge.sh'
- ./scripts/create-demo-certificates.sh
- ./scripts/create-iot-hub-devices.sh
- ./scripts/upload-files.sh
- ssh cayers@cayers-edge-test-gateway.eastus.cloudapp.azure.com sudo reboot
- ssh cayers@cayers-edge-test-client1.eastus.cloudapp.azure.com sudo reboot
- ssh cayers@cayers-edge-test-client2.eastus.cloudapp.azure.com sudo reboot
- 
