@description('Create a Container Apps managed environment')
param name string
param location string
param logAnalyticsWorkspaceId string
param tags object = {}

resource env 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: last(split(logAnalyticsWorkspaceId, '/'))
        sharedKey: ''
      }
    }
  }
}

output environmentId string = env.id
targetScope = 'resourceGroup'

@description('Azure region for the Container Apps environment.')
param location string

@description('Resource tags.')
param tags object = {}

@description('Container Apps environment name.')
param containerEnvironmentName string

@description('Subnet resource ID for the Container Apps environment.')
param infrastructureSubnetId string

@description('Log Analytics workspace resource name used by the environment.')
param logAnalyticsWorkspaceName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
    vnetConfiguration: {
      infrastructureSubnetId: infrastructureSubnetId
    }
  }
}

output containerEnvironmentResourceId string = containerEnvironment.id
output containerEnvironmentName string = containerEnvironment.name
