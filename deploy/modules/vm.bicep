@description('The name of you Virtual Machine.')
param vmName string = 'simpleLinuxVM'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}')

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '18.04-LTS'
  '20.04-LTS'
])
param ubuntuOSVersion string = '18.04-LTS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM')
param vmSize string = 'Standard_B2s'

@description('Id of the Internet subnet in the virtual network')
param internetSubnetId string

@description('Id of the Private subnet in the virtual network')
param privateSubnetId string

@description('Name of the Network Security Group')
param networkSecurityGroupName string = 'SecGroupNet'

var publicIPAddressName = '${vmName}-PublicIP'
var inetNetworkInterfaceName = '${vmName}-NetInt'
var privateNetworkInterfaceName = '${vmName}-NetPri'
var osDiskType = 'Standard_LRS'

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: inetNetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: internetSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource nic2 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: privateNetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          subnet: {
            id: privateSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties:{
            primary: true
          }
        }
        {
          id: nic2.id
          properties:{
            primary: false
          }
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
}

output adminUsername string = adminUsername
output hostname string = publicIP.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIP.properties.dnsSettings.fqdn}'



// {
//   "apiVersion": "[providers('Microsoft.DevTestLab','labs').apiVersions[0]]",
//   "type": "microsoft.devtestlab/schedules",
//   "name": "[concat('shutdown-computevm-',parameters('vmName'),copyIndex(parameters('numerationOfVMs')))]",
//   "location": "[resourceGroup().location]",
//   "dependsOn": [
//       "[concat('Microsoft.Compute/virtualMachines/',concat(parameters('vmName'),copyIndex(parameters('numerationOfVMs'))))]"
//   ],
//   "properties": {
//       "status": "Enabled",
//       "taskType": "ComputeVmShutdownTask",
//       "dailyRecurrence": {
//           "time": "1900"
//       },
//       "timeZoneId": "W. Europe Standard Time",
//       "notificationSettings": {
//           "status": "Disabled",
//           "timeInMinutes": 15
//       },
//       "targetResourceId": "[resourceId('Microsoft.Compute/virtualMachines',concat(parameters('vmName'),copyIndex(parameters('numerationOfVMs'))))]"
//   }
// }