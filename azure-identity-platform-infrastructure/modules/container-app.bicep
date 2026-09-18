@description('Create a Container App (sample)')
param name string
param location string
param containerEnvironmentId string
param containerImage string
param tags object = {}
param minReplicas int = 1
param maxReplicas int = 2

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'Auto'
      }
      registries: []
    }
    template: {
      containers: [
        {
          name: 'app'
          properties: {
            image: containerImage
            resources: {
              cpu: 0.25
              memory: '0.5Gi'
            }
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output environmentId string = containerApp.properties.managedEnvironmentId
output systemAssignedPrincipalId string = containerApp.identity.principalId
targetScope = 'resourceGroup'

@description('Azure region for the container app.')
param location string

@description('Resource tags.')
param tags object = {}

@description('Name of the container app.')
param containerAppName string

@description('Resource ID of the managed environment.')
param managedEnvironmentId string

@description('Container image to deploy.')
param containerImage string

@description('Container registry login server.')
param containerRegistryLoginServer string

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('Key Vault URI.')
param keyVaultUri string

@description('SQL server FQDN.')
param sqlServerFullyQualifiedDomainName string

@description('SQL database name.')
param sqlDatabaseName string

@description('CPU allocation.')
param cpu string = '0.5'

@description('Memory allocation.')
param memory string = '1Gi'

@description('Minimum replicas.')
param minReplicas int = 1

@description('Maximum replicas.')
param maxReplicas int = 2

@description('Ingress target port.')
param targetPort int = 80

@description('Environment name.')
param environmentName string

var managedIdentityName = '${containerAppName}-mi'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: managedEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
      }
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistryLoginServer
          identity: userAssignedIdentity.id
        }
      ]
      secrets: []
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            {
              name: 'APP_ENVIRONMENT'
              value: environmentName
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'KEY_VAULT_URI'
              value: keyVaultUri
            }
            {
              name: 'SQL_SERVER_FQDN'
              value: sqlServerFullyQualifiedDomainName
            }
            {
              name: 'SQL_DATABASE_NAME'
              value: sqlDatabaseName
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/'
                port: targetPort
                scheme: 'HTTP'
              }
              initialDelaySeconds: 30
              periodSeconds: 30
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output principalId string = userAssignedIdentity.properties.principalId
