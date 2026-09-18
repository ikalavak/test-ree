@description('Name of the deployment environment (sandbox, nonprod, prod)')
param environmentName string = 'sandbox'

@description('Azure region to deploy to')
param location string = resourceGroup().location

@description('Common tags applied to resources')
param tags object = {
  project: 'azure-identity-platform'
  env: environmentName
}

@description('Container image to use for the sample container apps (public sample).')
param containerImage string = 'mcr.microsoft.com/oss/nginx/nginx:1.21'

@description('ACR name (will be used to create ACR)')
param acrName string = 'identityplatformacr${uniqueString(resourceGroup().id)}'

@description('SQL admin username')
param sqlAdmin string = 'sqladminuser'

@description('SQL administrator password (secure)')
@secure()
param sqlAdminPassword string

@description('Virtual network address prefix')
param vnetPrefix string = '10.0.0.0/16'

@description('Application subnet prefix')
param appSubnetPrefix string = '10.0.1.0/24'

@description('Private endpoint subnet prefix')
param peSubnetPrefix string = '10.0.2.0/24'

// Modules
module networking 'modules/networking.bicep' = {
  name: 'networking'
  params: {
    location: location
    vnetPrefix: vnetPrefix
    appSubnetPrefix: appSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
    tags: tags
  }
}

module acr 'modules/container-registry.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: 'Standard'
    tags: tags
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    environmentName: environmentName
    tags: tags
  }
}

module containerEnv 'modules/container-environment.bicep' = {
  name: 'containerEnv'
  params: {
    name: 'identity-env-${environmentName}'
    location: location
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    name: 'kv-${environmentName}-${uniqueString(resourceGroup().id)}'
    tags: tags
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    administratorLogin: sqlAdmin
    administratorLoginPassword: sqlAdminPassword
    tags: tags
  }
}

// Create two container apps (identity-api and partner-api) using a public sample image.
module identityApp 'modules/container-app.bicep' = {
  name: 'identityApp'
  params: {
    name: 'identity-api-${environmentName}'
    location: location
    containerEnvironmentId: containerEnv.outputs.environmentId
    containerImage: containerImage
    tags: tags
    minReplicas: 1
    maxReplicas: 2
  }
}

module partnerApp 'modules/container-app.bicep' = {
  name: 'partnerApp'
  params: {
    name: 'partner-api-${environmentName}'
    location: location
    containerEnvironmentId: containerEnv.outputs.environmentId
    containerImage: containerImage
    tags: tags
    minReplicas: 1
    maxReplicas: 2
  }
}

module diagnostics 'modules/diagnostics.bicep' = {
  name: 'diagnostics'
  params: {
    location: location
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    applicationInsightsId: monitoring.outputs.appInsightsId
    tags: tags
  }
}

module rbac 'modules/role-assignments.bicep' = {
  name: 'rbac'
  params: {
    acrResourceId: acr.outputs.registryId
    containerAppIdentityPrincipalId: identityApp.outputs.systemAssignedPrincipalId
    tags: tags
  }
}

// Outputs
output containerEnvironmentId string = containerEnv.outputs.environmentId
output acrLoginServer string = acr.outputs.loginServer
output keyVaultId string = keyvault.outputs.keyVaultId
output sqlServerName string = sql.outputs.sqlServerName
targetScope = 'subscription'

@description('The Azure environment name to deploy into.')
param environmentName string

@description('The Azure region for all resources.')
param location string

@description('Short application name used for resource naming.')
param appName string = 'idp'

@description('Tags to apply to the deployment.')
param tags object = {}

@description('Identity API container image.')
param identityApiImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Partner API container image.')
param partnerApiImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('CPU allocation for each container app.')
param containerAppCpu string = '0.5'

@description('Memory allocation for each container app.')
param containerAppMemory string = '1Gi'

@description('Minimum replicas for each container app.')
param minReplicas int = 1

@description('Maximum replicas for each container app.')
param maxReplicas int = 2

@description('Virtual network address space.')
param vnetAddressSpace string = '10.20.0.0/16'

@description('Application subnet address prefix.')
param appSubnetPrefix string = '10.20.1.0/24'

@description('Private endpoint subnet address prefix.')
param privateEndpointSubnetPrefix string = '10.20.10.0/24'

@description('Azure SQL administrator login.')
param sqlAdministratorLogin string = 'sqladminuser'

@description('Azure SQL administrator password. Replace with a secure secret in production.')
@secure()
param sqlAdministratorPassword string

@description('Key Vault tenant ID.')
param keyVaultTenantId string = tenant().tenantId

@description('Container app target port.')
param targetPort int = 80

var resourceToken = toLower('${appName}-${environmentName}')
var resourceGroupName = 'rg-${resourceToken}'
var logAnalyticsWorkspaceName = 'law-${resourceToken}'
var applicationInsightsName = 'appi-${resourceToken}'
var containerEnvironmentName = 'cae-${resourceToken}'
var containerRegistryName = toLower(replace('acr${resourceToken}', '-', ''))
var containerAppTags = union(tags, {
  environment: environmentName
  workload: 'identity-platform'
  app: appName
})

module resourceGroup 'modules/resource-group.bicep' = {
  name: 'resourceGroup'
  params: {
    name: resourceGroupName
    location: location
    tags: containerAppTags
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup
  ]
  params: {
    location: location
    tags: containerAppTags
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    containerAppResourceId: ''
  }
}

module networking 'modules/networking.bicep' = {
  name: 'networking'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup
  ]
  params: {
    location: location
    tags: containerAppTags
    vnetName: 'vnet-${resourceToken}'
    nsgName: 'nsg-${resourceToken}'
    appSubnetName: 'snet-app'
    privateEndpointSubnetName: 'snet-pe'
    vnetAddressSpace: vnetAddressSpace
    appSubnetPrefix: appSubnetPrefix
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
  }
}

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup
  ]
  params: {
    location: location
    tags: containerAppTags
    acrName: containerRegistryName
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup
    networking
  ]
  params: {
    location: location
    tags: containerAppTags
    keyVaultName: 'kv-${resourceToken}'
    tenantId: keyVaultTenantId
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    privateDnsZoneId: networking.outputs.keyVaultPrivateDnsZoneId
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup
    networking
  ]
  params: {
    location: location
    tags: containerAppTags
    sqlServerName: 'sql-${resourceToken}'
    sqlDatabaseName: 'identityplatformdb'
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorPassword: sqlAdministratorPassword
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    privateDnsZoneId: networking.outputs.sqlPrivateDnsZoneId
  }
}

module containerEnvironment 'modules/container-environment.bicep' = {
  name: 'containerEnvironment'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup
    monitoring
    networking
  ]
  params: {
    location: location
    tags: containerAppTags
    containerEnvironmentName: containerEnvironmentName
    infrastructureSubnetId: networking.outputs.appSubnetId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module identityApi 'modules/container-app.bicep' = {
  name: 'identityApi'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerEnvironment
    containerRegistry
    keyVault
    sql
  ]
  params: {
    location: location
    tags: containerAppTags
    containerAppName: 'identity-api'
    managedEnvironmentId: containerEnvironment.outputs.containerEnvironmentResourceId
    containerImage: identityApiImage
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    keyVaultUri: keyVault.outputs.uri
    sqlServerFullyQualifiedDomainName: sql.outputs.sqlServerFullyQualifiedDomainName
    sqlDatabaseName: sql.outputs.sqlDatabaseName
    cpu: containerAppCpu
    memory: containerAppMemory
    minReplicas: minReplicas
    maxReplicas: maxReplicas
    targetPort: targetPort
    environmentName: environmentName
  }
}

module partnerApi 'modules/container-app.bicep' = {
  name: 'partnerApi'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerEnvironment
    containerRegistry
    keyVault
  ]
  params: {
    location: location
    tags: containerAppTags
    containerAppName: 'partner-api'
    managedEnvironmentId: containerEnvironment.outputs.containerEnvironmentResourceId
    containerImage: partnerApiImage
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    keyVaultUri: keyVault.outputs.uri
    sqlServerFullyQualifiedDomainName: sql.outputs.sqlServerFullyQualifiedDomainName
    sqlDatabaseName: sql.outputs.sqlDatabaseName
    cpu: containerAppCpu
    memory: containerAppMemory
    minReplicas: minReplicas
    maxReplicas: maxReplicas
    targetPort: targetPort
    environmentName: environmentName
  }
}

module roleAssignments 'modules/role-assignments.bicep' = {
  name: 'roleAssignments'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    identityApi
    partnerApi
    keyVault
    containerRegistry
  ]
  params: {
    acrName: containerRegistry.outputs.name
    keyVaultName: keyVault.outputs.name
    principalIds: [
      identityApi.outputs.principalId
      partnerApi.outputs.principalId
    ]
  }
}

module diagnostics 'modules/diagnostics.bicep' = {
  name: 'diagnostics'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    monitoring
    keyVault
    sql
    containerRegistry
    containerEnvironment
  ]
  params: {
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    keyVaultName: keyVault.outputs.name
    sqlServerName: sql.outputs.sqlServerName
    containerRegistryName: containerRegistry.outputs.name
    containerEnvironmentName: containerEnvironment.outputs.containerEnvironmentName
  }
}

output resourceGroupName string = resourceGroup.outputs.name
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
output containerEnvironmentName string = containerEnvironment.outputs.containerEnvironmentName
output containerRegistryName string = containerRegistry.outputs.name
output keyVaultName string = keyVault.outputs.name
output sqlServerFullyQualifiedDomainName string = sql.outputs.sqlServerFullyQualifiedDomainName
output identityApiFqdn string = identityApi.outputs.fqdn
output partnerApiFqdn string = partnerApi.outputs.fqdn
