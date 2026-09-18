@description('Create an Azure Container Registry')
param name string
param location string
param sku string = 'Standard'
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
  }
}

output registryId string = acr.id
output loginServer string = acr.properties.loginServer
targetScope = 'resourceGroup'

@description('Azure region for the container registry.')
param location string

@description('Resource tags.')
param tags object = {}

@description('Container registry name.')
param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

output name string = acr.name
output loginServer string = acr.properties.loginServer
output resourceId string = acr.id
