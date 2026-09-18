targetScope = 'resourceGroup'

@description('Resource group name.')
param name string

@description('Azure region for the resource group.')
param location string

@description('Resource tags.')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
  tags: tags
}

output name string = rg.name
output resourceId string = rg.id
