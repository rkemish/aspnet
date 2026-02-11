@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name used to derive resource names')
param appName string

@description('App Service Plan SKU (must be Standard or higher for deployment slots)')
param appServicePlanSku string = 'S1'

@description('App Configuration SKU')
param appConfigSku string = 'free'

// ──────────────────────────────────────────────
// Variables
// ──────────────────────────────────────────────

var appConfigDataReaderRoleId = '516239f1-63e1-4d78-a4de-a74fb236a071'

var themeDefaults = [
  { key: 'Primary', value: '#6366f1' }
  { key: 'PrimaryDark', value: '#4f46e5' }
  { key: 'Secondary', value: '#0ea5e9' }
  { key: 'Accent', value: '#f59e0b' }
  { key: 'Background', value: '#f8fafc' }
  { key: 'Surface', value: '#ffffff' }
  { key: 'TextPrimary', value: '#0f172a' }
  { key: 'TextSecondary', value: '#475569' }
  { key: 'TextMuted', value: '#94a3b8' }
  { key: 'Border', value: '#e2e8f0' }
  { key: 'NavBackground', value: '#0f172a' }
  { key: 'NavText', value: '#f8fafc' }
  { key: 'FooterBackground', value: '#1e293b' }
  { key: 'FooterText', value: '#94a3b8' }
]

// ──────────────────────────────────────────────
// App Configuration Store
// ──────────────────────────────────────────────

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: '${appName}-config'
  location: location
  sku: {
    name: appConfigSku
  }
}

// ──────────────────────────────────────────────
// Seed Theme Key-Values
// ──────────────────────────────────────────────

resource themeKeyValues 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = [
  for item in themeDefaults: {
    parent: appConfig
    name: 'Theme:${item.key}'
    properties: {
      value: item.value
    }
  }
]

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
// Web App (Linux, .NET 10) with Managed Identity
// ──────────────────────────────────────────────

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: true
      appSettings: [
        {
          name: 'AppConfiguration__Endpoint'
          value: appConfig.properties.endpoint
        }
      ]
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
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: true
      appSettings: [
        {
          name: 'AppConfiguration__Endpoint'
          value: appConfig.properties.endpoint
        }
      ]
    }
    httpsOnly: true
  }
}

// ──────────────────────────────────────────────
// Role Assignments — App Configuration Data Reader
// ──────────────────────────────────────────────

resource webAppConfigRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appConfig.id, webApp.id, appConfigDataReaderRoleId)
  scope: appConfig
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      appConfigDataReaderRoleId
    )
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource stagingSlotConfigRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appConfig.id, stagingSlot.id, appConfigDataReaderRoleId)
  scope: appConfig
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      appConfigDataReaderRoleId
    )
    principalId: stagingSlot.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

output webAppName string = webApp.name
output webAppDefaultHostName string = webApp.properties.defaultHostName
output stagingSlotUrl string = stagingSlot.properties.defaultHostName
output appConfigEndpoint string = appConfig.properties.endpoint
output appConfigName string = appConfig.name
