# Azure Identity Platform Infrastructure (Bicep PoC)

Problem: Provide a reusable, environment-driven IaC prototype that demonstrates how an Identity Platform's infrastructure is deployed and managed on Azure using Bicep.

Architecture (ASCII):

Users / Partners
  |
  v
  Identity Platform (Container Apps)
  |
  v
  Azure Container Apps
  |  +--> Azure SQL
  |  +--> Key Vault
  |  +--> Container Registry
  v
  Monitoring --> Application Insights + Log Analytics

Infra managed by GitHub Actions -> Bicep -> Azure

What is included
- `main.bicep` — orchestrates modules and outputs
- `modules/` — reusable modules: networking, acr, container-environment, container-app, keyvault, sql, monitoring, diagnostics, role-assignments
- `environments/` — `sandbox`, `nonprod`, `prod` parameter files
- `.github/workflows/deploy.yml` — CI/CD pipeline skeleton using Bicep build, What-If and deployment

Design notes
- Single codebase; environment drift is prevented by parameter-driven deployments and Git-based CI with What-If validations.
- Container Apps use a public sample image for quick demos. ACR exists for private images; use the role-assignments module to grant `AcrPull` to the container app identity.
- Key Vault is provisioned with secure defaults; do not check secrets into source control.
- SQL Server + Basic database is created for demo; replace SKU for production.

Cost guidance
- The PoC uses low-cost SKUs (Log Analytics Free, SQL Basic). Remove or deallocate resources after the interview to avoid charges.

Deployment commands (CLI)
Create resource group:
```
az group create -n rg-identity-platform-demo -l eastus
```
Validate / build Bicep:
```
bicep build main.bicep
```
What-If:
```
az deployment group what-if --resource-group rg-identity-platform-demo --template-file main.bicep --parameters @environments/sandbox.bicepparam
```
Deploy:
```
az deployment group create --resource-group rg-identity-platform-demo --template-file main.bicep --parameters @environments/sandbox.bicepparam
```
Cleanup:
```
az group delete -n rg-identity-platform-demo --yes --no-wait
```



This repository contains a reusable Azure Bicep proof-of-concept for an identity platform infrastructure targeting internal users and external partners. The emphasis is on infrastructure deployment, networking, monitoring, secure access, and repeatable environment separation rather than implementing a real customer identity system.

## 1. Problem statement

The organization is moving away from Azure AD B2C and needs a secure, repeatable Azure foundation for an Identity Platform. This prototype models the supporting infrastructure only. It intentionally does not implement real authentication flows, customer identity management, tokens, or production identity services.

## 2. Proposed architecture

The architecture includes a resource group, VNet, app subnet, private endpoint subnet, Azure Container Apps Environment, ACR, Key Vault, Azure SQL, Log Analytics, Application Insights, Azure Monitor, managed identity, and private endpoints for data services.


![Uploading ChatGPT Image Sep 18, 2026 at 12_35_07 PM.png…]()









## 3. Azure services

- Azure Resource Group
- Azure Virtual Network
- Network Security Group
- Azure Container Apps Environment
- Azure Container Apps
- Azure Container Registry
- Azure Key Vault
- Azure SQL Database
- Log Analytics Workspace
- Application Insights
- Azure Monitor / metric alerts
- Managed Identity
- Private DNS Zones
- Private Endpoints
- Azure RBAC

## 4. Bicep structure

```text
azure-identity-platform-infrastructure/
├── main.bicep
├── modules/
│   ├── resource-group.bicep
│   ├── networking.bicep
│   ├── container-registry.bicep
│   ├── container-environment.bicep
│   ├── container-app.bicep
│   ├── keyvault.bicep
│   ├── sql.bicep
│   ├── monitoring.bicep
│   ├── diagnostics.bicep
│   ├── role-assignments.bicep
├── environments/
│   ├── sandbox.bicepparam
│   ├── nonprod.bicepparam
│   └── prod.bicepparam
├── .github/
│   └── workflows/
│       └── deploy.yml
├── README.md
└── .gitignore
```

## 5. Environment strategy

A single reusable Bicep codebase is parameterized by environment-specific `.bicepparam` files:

- sandbox
- nonprod
- prod

The same modules are reused, while parameter files control:

- environment names
- locations
- tags
- resource names
- subnet ranges
- replica sizing
- SKU selections

## 6. Security approach

- Managed identities are used for Container Apps and registry access.
- Azure RBAC grants least-privilege permissions for Key Vault and ACR.
- Key Vault uses RBAC authorization with private access.
- Azure SQL is configured for private access and TLS 1.2.
- Network access is restricted by VNet and private endpoints.
- No hard-coded credentials are committed to source control.
- HTTPS ingress is enabled for container apps.

This is not a production identity implementation; it is a secure infrastructure foundation for an interview proof of concept.

## 7. Monitoring approach

- Log Analytics Workspace centralizes operational logs.
- Application Insights provides application telemetry.
- Diagnostic settings are attached to Key Vault, SQL, ACR, and the Container Apps environment.
- Azure Monitor metric alert is included as a simple health signal example.

## 8. CI/CD approach

The GitHub Actions pipeline includes:

1. Pull request trigger
2. Bicep build validation
3. Parameter file validation
4. What-If execution
5. Approval through GitHub environment support
6. Deployment to the selected environment

GitHub OIDC is used as the preferred authentication model instead of long-lived secrets.

## 9. Configuration drift strategy

This design reduces drift by using:

- a single source of truth in Bicep
- environment-specific parameter files
- pull request review gates
- pre-deployment What-If validation
- controlled deployment through GitHub Actions
- version-controlled infrastructure changes

## 10. Deployment instructions

### Prerequisites

- Azure subscription
- Azure CLI installed
- logged in to Azure
- Bicep CLI installed
- GitHub repo configured with OIDC and Azure secrets

### Login

```bash
az login
az account set --subscription "<your-subscription-id-or-name>"
```

### Deploy sandbox

```bash
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters @environments/sandbox.bicepparam
```

### Deploy nonprod

```bash
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters @environments/nonprod.bicepparam
```

### Deploy prod

```bash
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters @environments/prod.bicepparam
```

### What-If command

```bash
az deployment sub what-if \
  --location eastus \
  --template-file main.bicep \
  --parameters @environments/sandbox.bicepparam
```

## 11. Cleanup instructions

```bash
az group delete --name rg-idp-sandbox --yes --no-wait
```

Or delete the full environment resource group by matching the generated name for the chosen environment.

## 12. Interview talking points

- This is an infrastructure-only proof of concept, not a production identity platform.
- The design uses Azure-native services and Bicep for secure, repeatable provisioning.
- Container Apps support the platform APIs with managed identity and private networking.
- Azure SQL and Key Vault are protected with private endpoints and RBAC.
- Monitoring is built into the architecture from the start.
- Parameterized environment files make the same code reusable for sandbox and production.
- The GitHub workflow shows a mature deployment model with validation and approvals.

## ASCII architecture diagram

```text
Users / Partners
      |
      v
Identity Platform
      |
      v
Azure Container Apps
   +------> Azure SQL
   |
   +------> Key Vault
   |
   +------> Container Registry
   |
   v
Monitoring
   +------> Application Insights
   +------> Log Analytics
   +------> Azure Monitor

Infrastructure is managed by:
GitHub
   |
   v
GitHub Actions
   |
   v
Bicep
   |
   v
Azure
```

## Notes

- This is intentionally low-cost and suitable for a demo or interview scenario.
- Azure SQL uses a small Basic tier and private networking.
- Container images use public sample images for demonstration purposes only.
- Replace sample passwords and environment values with secure secret management in real deployment.
