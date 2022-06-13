@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment. This must be nonprod or prod.')
@allowed([
  'dev'
  'qa'
  'prod'
])
param environment string

@description('Specify the base name.')
param baseName string

param adminPassword string

param adminUsername string

param childCount int = 1

module iotHub 'modules/iot.bicep' = {
  name: 'iotDeploy'
  params: {
      location: location
      iotHubName: '${baseName}-${environment}'
      provisioningServiceName: '${baseName}-${environment}-dps'
  }
}

module vnet 'modules/vnet.bicep' = {
  name: '${baseName}-vnet'
  params: {
    virtualNetworkName: '${baseName}-vnet'
  }
}


module vmGateway 'modules/vm.bicep' = {
  name: '${baseName}-gateway'
  params: {
    vmName: '${baseName}-gateway'
    adminPassword: adminPassword
    adminUsername: adminUsername
    internetSubnetId: vnet.outputs.internetSubnetId
    privateSubnetId: vnet.outputs.privateSubnetId
    networkSecurityGroupName: '${baseName}-gateway-NSG'
  }
  dependsOn: [
    vnet
  ]
}

module vmChild 'modules/vm.bicep' = [for i in range(0, childCount): {
  name: '${baseName}-child${i}'
  params: {
    vmName: '${baseName}-child1'
    adminPassword: adminPassword
    adminUsername: adminUsername
    internetSubnetId: vnet.outputs.internetSubnetId
    privateSubnetId: vnet.outputs.privateSubnetId
    networkSecurityGroupName: '${baseName}-child${i}-NSG'
  }
  dependsOn: [
    vnet
  ]
} ]

module acr 'modules/acr.bicep' = {
  name: 'acr${baseName}'
  params: {
    baseName: baseName
  }
}

output vmGatewaySSH string = vmGateway.outputs.sshCommand

output vmChildSSH array = [for i in range(0, childCount): {
  sshCommand: vmChild[i].outputs.sshCommand
}]
