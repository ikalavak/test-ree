{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "prod"
    },
    "location": {
      "value": "centralus"
    },
    "tags": {
      "value": {
        "owner": "identity-platform",
        "costCenter": "prod"
      }
    },
    "sqlAdminPassword": {
      "reference": {
        "keyVault": {
          "id": ""
        },
        "secretName": ""
      }
    }
  }
}
using '../main.bicep'

param environmentName = 'prod'
param location = 'eastus2'
param appName = 'idp'
param tags = {
  environment: 'prod'
  owner: 'platform-team'
  costCenter: 'engineering'
  application: 'identity-platform'
}
param identityApiImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param partnerApiImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param containerAppCpu = '0.5'
param containerAppMemory = '1Gi'
param minReplicas = 2
param maxReplicas = 5
param vnetAddressSpace = '10.22.0.0/16'
param appSubnetPrefix = '10.22.1.0/24'
param privateEndpointSubnetPrefix = '10.22.10.0/24'
param targetPort = 80
param sqlAdministratorLogin = 'sqladminuser'
param sqlAdministratorPassword = 'P@ssw0rd!23456' // placeholder only for demo; use secure secret in actual deployments
