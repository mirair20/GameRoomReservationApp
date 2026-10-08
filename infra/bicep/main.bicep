targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'germanywestcentral'

@description('Name of the resource group')
param resourceGroupName string = 'GameRoomBookingSystem'

@description('Base name used to derive resource names')
param appBaseName string = 'gameroombooking'

@description('SKU for the App Service Plan')
param appServicePlanSku string = 'B1'

@description('Container image and tag to deploy, e.g. gameroombookingsys:latest. Defaults to a placeholder until you push your own image.')
param containerImage string = 'appsvc/staticsite:latest'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module acr 'modules/containerRegistry.bicep' = {
  name: 'acrDeployment'
  scope: rg
  params: {
    location: location
    acrName: '${appBaseName}acr'
  }
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlanDeployment'
  scope: rg
  params: {
    location: location
    planName: '${appBaseName}-plan'
    sku: appServicePlanSku
  }
}

module webApp 'modules/webApp.bicep' = {
  name: 'webAppDeployment'
  scope: rg
  params: {
    location: location
    webAppName: '${appBaseName}-app'
    appServicePlanId: appServicePlan.outputs.planId
    acrLoginServer: acr.outputs.loginServer
    containerImage: containerImage
  }
}

module acrRoleAssignment 'modules/acrRoleAssignment.bicep' = {
  name: 'acrRoleAssignmentDeployment'
  scope: rg
  params: {
    acrName: '${appBaseName}acr'
    principalId: webApp.outputs.principalId
  }
}

output acrLoginServer string = acr.outputs.loginServer
output webAppName string = webApp.outputs.webAppName
output webAppUrl string = 'https://${webApp.outputs.defaultHostName}'
