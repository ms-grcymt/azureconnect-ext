param naming object
@allowed([
  'prod'
  'dev'
])
param environmentType string = 'dev'

param location string = resourceGroup().location
param vnetAddressPrefix string = ''
param tags object
param dbAdministratorLogin string = 'dbadmin'
@secure()
param dbAdministratorPassword string
@secure()
param bingMapsKey string
param acrLoginServer string
param acrUsername string
@secure()
param acrPassword string

var resourceNames = {
  userAssignIdentity: 'uai-${naming.appServicePlan.nameUnique}'
  keyVault: naming.keyVault.nameUnique  
  appServicePlan: naming.appServicePlan.name
  poiApp: replace(naming.appService.name, 'app-', 'api-poi-')
  tripsApp: replace(naming.appService.name, 'app-', 'api-trips-')
  userJavaApp: replace(naming.appService.name, 'app-', 'api-userjava-')
  userProfileApp: replace(naming.appService.name, 'app-', 'api-userprofile-')
  tripViewerApp: replace(naming.appService.name, 'app-', 'app-tripviewer-')
  vnet: naming.virtualNetwork.name
  subnetPrefix: naming.subnet.name
  bastion: naming.bastionHost.name
  sqlServer: naming.mssqlServer.name
  sqlDatabase: naming.mssqlDatabase.name
  storage: naming.storageAccount.nameUnique
}

var secretNames = {
  sqlServerName: 'sqlServerName'
  sqlDatabaseName: 'sqlDatabaseName'
  sqlUsername: 'sqlUsername'
  sqlPassword: 'sqlPassword'
  storageConnectionString: 'storageConnectionString'
}

var isProductionType = environmentType == 'prod'

var acrAppSettings = [
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: acrLoginServer
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
    value: acrUsername
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
    value: acrPassword
  }
]

var commonAppSettings = concat([
  {
    name: 'SQL_USER'
    value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.sqlUsername})'
  }
  {
    name: 'SQL_PASSWORD'
    value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.sqlPassword})'
  }
  {
    name: 'SQL_SERVER'
    value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.sqlServerName})'
  }
  {
    name: 'SQL_DBNAME'
    value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.sqlDatabaseName})'
  }
  {
    name: 'STORAGE_CONNECTIONSTING'
    value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.storageConnectionString})'
  }
], acrAppSettings)

module vnet 'modules/vnet.module.bicep' = if (isProductionType) {
  name: 'VnetDeployment'
  params: {
    name: resourceNames.vnet
    location: location
    subnetNamePrefix: resourceNames.subnetPrefix
    addressPrefix: vnetAddressPrefix
    includeBastion: true
    tags: tags
  }
}

module bastion 'modules/bastion.module.bicep' = if (isProductionType) {
  name: 'bastionDeployment'
  params: {
    name: resourceNames.bastion
    location: location
    subnetId: isProductionType ? vnet.outputs.bastionSnetId : ''
  }
}

module sqlServer 'modules/sqlServer.module.bicep' = {
  name: 'SqlServerDeployment'
  params: {
    name: resourceNames.sqlServer
    databaseName: resourceNames.sqlDatabase
    administratorLogin: dbAdministratorLogin
    administratorLoginPassword: dbAdministratorPassword
    databaseEdition: 'Standard'
    databaseServiceObjective: isProductionType ? 'S3' : 'S2'
  }
}

module appServicePlan 'modules/appServicePlan.module.bicep' = {
  name: 'AppServicePlanDeployement'
  params: {
    name: resourceNames.appServicePlan
    location: location
    skuName: isProductionType ? 'P3v3' : 'P2v3'
    tags: tags
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: resourceNames.userAssignIdentity
  location: location
}

module poiApp 'modules/webApps.module.bicep' = {
  name: 'WebApiAppsDeployment'
  params: {
    name: resourceNames.poiApp
    location: location
    appServicePlanName: appServicePlan.outputs.name
    includeStagingSlot: true
    managedIdentity: userAssignedIdentity.id
    appSettings: concat(commonAppSettings, [
      {
        name: 'WEBSITES_PORT'
        value: '8080'
      }
    ])
    containerApplicationTag: '${acrLoginServer}/azconnect/api-poi:latest'
    subnetIdForIntegration: isProductionType ? vnet.outputs.integratedSnetId : ''
    tags: tags
  }
}

module userJavaApp 'modules/webApps.module.bicep' = {
  name: 'UserJavaAppDeployment'
  params: {
    name: resourceNames.userJavaApp
    location: location
    appServicePlanName: appServicePlan.outputs.name
    includeStagingSlot: true
    managedIdentity: userAssignedIdentity.id
    appSettings: commonAppSettings
    containerApplicationTag: '${acrLoginServer}/azconnect/api-user-java:latest'
    subnetIdForIntegration: isProductionType ? vnet.outputs.integratedSnetId : ''
    tags: tags
  }
}

module userProfileApp 'modules/webApps.module.bicep' = {
  name: 'UserProfileAppDeployment'
  params: {
    name: resourceNames.userProfileApp
    location: location
    appServicePlanName: appServicePlan.outputs.name
    includeStagingSlot: true
    managedIdentity: userAssignedIdentity.id 
    appSettings: concat(commonAppSettings, [
      {
        name: 'WEBSITES_PORT'
        value: '8080'
      }
    ])
    containerApplicationTag: '${acrLoginServer}/azconnect/api-userprofile:latest'
    subnetIdForIntegration: isProductionType ? vnet.outputs.integratedSnetId : ''
    tags: tags
  }
}

module tripsApp 'modules/webApps.module.bicep' = {
  name: 'TripsAppDeployment'
  params: {
    name: resourceNames.tripsApp
    location: location
    appServicePlanName: appServicePlan.outputs.name
    includeStagingSlot: true
    managedIdentity: userAssignedIdentity.id
    appSettings: commonAppSettings
    containerApplicationTag: '${acrLoginServer}/azconnect/api-trips:latest'
    subnetIdForIntegration: isProductionType ? vnet.outputs.integratedSnetId : ''
    tags: tags
  }
}

module tripViewerApp 'modules/webApps.module.bicep' = {
  name: 'TripViewerAppDeployment'
  params: {
    name: resourceNames.tripViewerApp
    location: location
    appServicePlanName: appServicePlan.outputs.name
    tags: tags
    containerApplicationTag: '${acrLoginServer}/azconnect/tripviewer:latest'
    appSettings: concat([
      {
        name: 'USER_ROOT_URL'
        value: 'https://${userProfileApp.outputs.siteHostName}'
      }
      {
        name: 'USER_JAVA_ROOT_URL'
        value: 'https://${userJavaApp.outputs.siteHostName}'
      }
      {
        name: 'TRIPS_ROOT_URL'
        value: 'https://${tripsApp.outputs.siteHostName}'
      }
      {
        name: 'POI_ROOT_URL'
        value: 'https://${poiApp.outputs.siteHostName}'
      }
      {
        name: 'BING_MAPS_KEY'
        value: bingMapsKey
      }      
    ], acrAppSettings)
  }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (isProductionType) {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

module poiAppPrivateEndpoint 'modules/privateEndpoint.module.bicep' = if (isProductionType) {
  name: 'PoiAppPrivateEndpoint'
  params: {
    name: '${resourceNames.poiApp}-pe'
    location: location
    tags: tags
    privateDnsZoneId: privateDNSZone.id
    privateLinkServiceId: poiApp.outputs.id
    subnetId: isProductionType ? vnet.outputs.appSnetId : ''
    subResource: 'sites'
  }
}

module tripsAppPrivateEndpoint 'modules/privateEndpoint.module.bicep' = if (isProductionType) {
  name: 'TripsAppPrivateEndpoint'
  params: {
    name: '${resourceNames.tripsApp}-pe'
    location: location
    tags: tags
    privateDnsZoneId: privateDNSZone.id
    privateLinkServiceId: tripsApp.outputs.id
    subnetId: isProductionType ? vnet.outputs.appSnetId : ''
    subResource: 'sites'
  }
}

module userJavaAppPrivateEndpoint 'modules/privateEndpoint.module.bicep' = if (isProductionType) {
  name: 'UserJavaAppPrivateEndpoint'
  params: {
    name: '${resourceNames.userJavaApp}-pe'
    location: location
    tags: tags
    privateDnsZoneId: privateDNSZone.id
    privateLinkServiceId: userJavaApp.outputs.id
    subnetId: isProductionType ? vnet.outputs.appSnetId : ''
    subResource: 'sites'
  }
}

module userProfileAppPrivateEndpoint 'modules/privateEndpoint.module.bicep' = if (isProductionType) {
  name: 'UserProfileAppPrivateEndpoint'
  params: {
    name: '${resourceNames.userProfileApp}-pe'
    location: location
    tags: tags
    privateDnsZoneId: privateDNSZone.id
    privateLinkServiceId: userProfileApp.outputs.id
    subnetId: isProductionType ? vnet.outputs.appSnetId : ''
    subResource: 'sites'
  }
}

module keyVault 'modules/keyvault.module.bicep' = {
  name: 'KeyVaultDeployment'
  params: {
    name: resourceNames.keyVault
    location: location
    skuName: 'premium'
    tags: tags
    accessPolicies: [
      {
        tenantId: userAssignedIdentity.properties.tenantId
        objectId: userAssignedIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
    secrets: [
      {
        name: secretNames.storageConnectionString
        value: storage.outputs.connectionString
      }
      {
        name: secretNames.sqlServerName
        value: sqlServer.outputs.fullyQualifiedDomainName
      }
      {
        name: secretNames.sqlDatabaseName
        value: naming.mssqlDatabase.name
      }
      {
        name: secretNames.sqlUsername
        value: dbAdministratorLogin
      }
      {
        name: secretNames.sqlPassword
        value: dbAdministratorPassword
      }
    ]
  }
}

module storage 'modules/storage.module.bicep' = {
  name: 'StorageAccountDeployment'
  params: {
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    name: resourceNames.storage
    tags: tags
  }
}

output storageAccountName string = storage.outputs.name
output sqlServerName string = resourceNames.sqlServer
output sqlServerFqdn string = sqlServer.outputs.fullyQualifiedDomainName
output sqlDatabaseName string = resourceNames.sqlDatabase
output sqlConnectionString string = sqlServer.outputs.connectionString
