param applicationName string
param environment string
param acrLoginServer string
param acrUsername string
@secure()
param acrPassword string

@allowed([
  'prod'
  'dev'
])
@description('The type of environment which dictates the tiers and setup of the resources created.')
param environmentType string = 'dev'
@description('The address space for the main vnet -applicable only when "environmentType" is "prod".')
param vnetAddressPrefix string = ''
param dbAdministratorLogin string = 'dbadmin'
@secure()
param dbAdministratorPassword string
@secure()
param bingMapsKey string
param tags object = {}

var defaultTags = union({
  applicationName: applicationName
  environment: environment
}, tags)

// Naming module to configure the naming conventions for Azure
module naming 'modules/naming.module.bicep' = {
  name: 'NamingDeployment'  
  params: {
    suffix: [
      applicationName
      environment
    ]
    uniqueLength: 6
    uniqueSeed: resourceGroup().id
  }
}

// Main deployment has all the resources to be deployed for 
// a workload in the scope of the specific resource group
module main 'main.bicep' = {
  name: 'MainDeployment'
  params: {
    location: resourceGroup().location
    naming: naming.outputs.names
    tags: defaultTags
    environmentType: environmentType
    dbAdministratorLogin: dbAdministratorLogin
    dbAdministratorPassword: dbAdministratorPassword
    vnetAddressPrefix: vnetAddressPrefix
    bingMapsKey: bingMapsKey
    acrLoginServer: acrLoginServer
    acrUsername: acrUsername
    acrPassword: acrPassword
  }
}

output storageAccountName string = main.outputs.storageAccountName
output sqlServerFqdn string = main.outputs.sqlServerFqdn
output sqlServerName string = main.outputs.sqlServerName
output sqlDatabaseName string = main.outputs.sqlDatabaseName
output sqlConnectionString string = main.outputs.sqlConnectionString
