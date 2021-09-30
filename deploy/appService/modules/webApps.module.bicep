param name string
param location string = resourceGroup().location
param tags object = {}
param appSettings array = []
param appServicePlanName string
param includeStagingSlot bool = false

@description('This is the container to be deployed in the format: {ACR_LOGIN_SERVER}/{CONTAINER_NAME}:{CONTAINER_TAG}')
param containerApplicationTag string = ''

@description('Whether to create a managed identity for the web app -defaults to \'false\'')
param managedIdentity string = ''

@description('The subnet Id to integrate the web app with -optional')
param subnetIdForIntegration string = ''

var webAppInsName = 'appins-${name}'

var createNetworkConfig = !empty(subnetIdForIntegration)

var networkConfigAppSettings = createNetworkConfig ? [
  {
    name: 'WEBSITE_VNET_ROUTE_ALL'
    value: '1'
  }
  {
    name: 'WEBSITE_DNS_SERVER'
    value: '168.63.129.16'
  }
] : []

var linuxFxVersion = empty(containerApplicationTag) ? 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest' : 'DOCKER|${containerApplicationTag}'

var identityConfig = empty(managedIdentity) ? {
  type: 'None'
} : (managedIdentity == 'SystemAssigned' ? {
  type: 'SystemAssigned'
} : {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${managedIdentity}': {}
  }
})

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' existing = {
  name: appServicePlanName
}

module webAppIns './appInsights.module.bicep' = {
  name: webAppInsName
  params: {
    name: webAppInsName
    location: location
    tags: tags
    project: name
  }
}

resource webApp 'Microsoft.Web/sites@2020-12-01' = {
  name: name
  location: location
  identity: identityConfig
  properties: {
    serverFarmId: appServicePlan.id
    keyVaultReferenceIdentity: identityConfig.type == 'UserAssigned' ? managedIdentity : json('null')
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: concat([
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: webAppIns.outputs.instrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${webAppIns.outputs.instrumentationKey}'
        }
      ], networkConfigAppSettings, appSettings)
    }
    //    httpsOnly: true  
  }
  tags: union({
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlan.name}': 'Resource'
  }, tags)
}

resource stagingSlot 'Microsoft.Web/sites/slots@2021-01-15' = if (includeStagingSlot) {
  name: '${webApp.name}/staging'
  location: location
  tags: tags
  identity: identityConfig
  properties: {
    serverFarmId: appServicePlan.id
    keyVaultReferenceIdentity: managedIdentity
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: concat([
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: webAppIns.outputs.instrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${webAppIns.outputs.instrumentationKey}'
        }
      ], networkConfigAppSettings, appSettings)
    }
  }
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = if (createNetworkConfig) {
  name: '${webApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: subnetIdForIntegration
  }
}

output id string = webApp.id
output name string = webApp.name
output applicationInsights object = webAppIns
output siteHostName string = webApp.properties.defaultHostName
