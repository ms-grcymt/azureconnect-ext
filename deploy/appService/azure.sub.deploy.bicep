targetScope = 'subscription'

param resourceGroupName string
param applicationName string
param environment string

@allowed([
  'prod'
  'dev'
])
@description('The type of environment which dictates the tiers and setup of the resources created.')
param environmentType string = 'dev'
@secure()
param bingMapsKey string
@secure()
param dbAdministratorPassword string
param tags object = {}

var defaultTags = union({
  applicationName: applicationName
  environment: environment
}, tags)

// Resource group which is the scope for the main deployment below
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
}

// Naming module to configure the naming conventions for Azure
module naming 'modules/naming.module.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'NamingDeployment'  
  params: {
    suffix: [
      applicationName
      environment
    ]
    uniqueLength: 6
    uniqueSeed: rg.id
  }
}

// Main deployment has all the resources to be deployed for 
// a workload in the scope of the specific resource group
module main 'main.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'MainDeployment'
  params: {
    location: rg.location
    naming: naming.outputs.names
    tags: defaultTags
    environmentType: environmentType
    dbAdministratorLogin: 'dbadmin'
    dbAdministratorPassword: dbAdministratorPassword
    bingMapsKey: bingMapsKey
  }
}

// Customize outputs as required from the main deployment module
output resourceGroupId string = rg.id
output resourceGroupName string = rg.name
