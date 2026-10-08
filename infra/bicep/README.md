# Bicep Setup Guide

This folder contains the Bicep templates that deploy the Game Room Booking System to Azure (resource group, Container Registry, Storage Account, App Service Plan, and Web App for Containers).

## 1. Prerequisites

- **Azure CLI** installed ([install guide](https://learn.microsoft.com/cli/azure/install-azure-cli))
- **Bicep CLI** (installs automatically the first time you run a `bicep`/`az bicep` command, or install manually):
  ```bash
  az bicep install
  ```
- An Azure subscription you can deploy to

Check your versions:
```bash
az version
az bicep version
```

## 2. Log in to Azure

```bash
az login
```

If you have more than one subscription, pick the right one:
```bash
az account set --subscription "<subscription-id-or-name>"
```

## 3. Validate the templates (optional but recommended)

Compile to check for syntax errors without deploying anything:
```bash
az bicep build --file infra/bicep/main.bicep --stdout
```

Or run a what-if deployment to preview changes:
```bash
az deployment sub what-if \
  --location germanywestcentral \
  --template-file infra/bicep/main.bicep
```

## 4. Deploy

`main.bicep` deploys at **subscription scope** (it creates the resource group itself), so use `az deployment sub create`:

```bash
az deployment sub create \
  --name gameroom-deployment \
  --location germanywestcentral \
  --template-file infra/bicep/main.bicep
```

Notes:
- `--location` here is only where Azure stores the deployment's metadata — it doesn't have to match the resources' region (set via the `location` parameter, default `germanywestcentral`).
- `communicationConnectionString` is an `@secure()` parameter — never hardcode secrets in the `.bicep` files or commit them to source control. Pass it on the command line, via `--parameters @params.json` with a gitignored file, or via a secret store/pipeline variable.
- Allowed Azure regions depend on your subscription's policies. If deployment fails with a region/policy error, check which regions you're allowed to use:
  ```bash
  az policy assignment list -o table
  ```

## 5. Push your container image

The Web App is created with a placeholder image. Build and push your real image to the registry this template created, then point the Web App at it.

> **Note:** ACR Tasks (cloud-side builds via `az acr build`) are blocked on Azure for Students subscriptions with a `TasksOperationsNotAllowed` error, so this guide uses a **local Docker build + push** instead — this uses plain registry push/pull, which isn't restricted.

**Prerequisite:** Docker Desktop/Engine installed and running locally.

```bash
# 1. Build the image locally (same context/dockerfile as docker-compose.yml)
docker build -t gameroombookingacr.azurecr.io/gameroombookingsys:latest -f Server/Dockerfile .

# 2. Authenticate Docker against your ACR
az acr login --name gameroombookingacr

# 3. Push the image
docker push gameroombookingacr.azurecr.io/gameroombookingsys:latest

# 4. Point the Web App at the new image
az webapp config container set \
  --name gameroombooking-app \
  --resource-group GameRoomBookingSystem \
  --container-image-name gameroombookingacr.azurecr.io/gameroombookingsys:latest
```

## 6. Useful follow-ups

```bash
# Tail live logs
az webapp log tail --name gameroombooking-app --resource-group GameRoomBookingSystem

# See deployment outputs (e.g. the app's URL)
az deployment sub show --name gameroom-deployment --query properties.outputs
```

## File structure

```
infra/bicep/
├── main.bicep                       # Entry point (subscription scope)
└── modules/
    ├── containerRegistry.bicep      # Azure Container Registry
    ├── storageaccount.bicep         # Storage account (StorageV2, Standard_LRS)
    ├── appServicePlan.bicep         # Linux App Service Plan
    ├── webApp.bicep                 # Linux Web App for Containers
    └── acrRoleAssignment.bicep      # Grants the Web App's managed identity AcrPull
```
