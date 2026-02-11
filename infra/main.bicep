@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name used to derive resource names')
param appName string

@description('App Service Plan SKU (must be Standard or higher for deployment slots)')
param appServicePlanSku string = 'S1'

// ──────────────────────────────────────────────
// App Service Plan (Linux)
// ──────────────────────────────────────────────

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${appName}-plan'
  location: location
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true // required for Linux
  }
}

// ──────────────────────────────────────────────
// Web App (Linux, .NET 10)
// ──────────────────────────────────────────────

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// ──────────────────────────────────────────────
// Staging Deployment Slot (blue-green)
// ──────────────────────────────────────────────

resource stagingSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  parent: webApp
  name: 'staging'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

output webAppName string = webApp.name
output webAppDefaultHostName string = webApp.properties.defaultHostName
output stagingSlotUrl string = stagingSlot.properties.defaultHostName
