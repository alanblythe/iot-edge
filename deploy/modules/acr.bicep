@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param baseName string

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

var acrName = 'acr${replace(baseName, '-', '')}'

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
