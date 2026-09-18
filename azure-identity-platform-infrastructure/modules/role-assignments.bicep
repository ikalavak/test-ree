@description('Assign AcrPull to a principal for ACR access (optional)')
param acrResourceId string
param containerAppIdentityPrincipalId string
param tags object = {}

// AcrPull role definition id (built-in) - if this changes, replace with correct GUID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','7f951dda-4ed3-4680-a7ca-43fe172d538d')

@allowed([ '','create' ])
param mode string = ''

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if (mode == 'create' && containerAppIdentityPrincipalId != '') {
  name: guid(acrResourceId, containerAppIdentityPrincipalId, acrPullRoleDefinitionId)
  properties: {
    principalId: containerAppIdentityPrincipalId
    roleDefinitionId: acrPullRoleDefinitionId
    scope: acrResourceId
  }
}

output roleAssignmentId string = roleAssignment.id
targetScope = 'resourceGroup'

@description('Azure Container Registry name.')
param acrName string

@description('Key Vault name.')
param keyVaultName string

@description('Principal IDs to grant access to.')
param principalIds array

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds: {
  name: guid(acr.id, principalId, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds: {
  name: guid(keyVault.id, principalId, 'KeyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

output assignedUserIds array = principalIds
