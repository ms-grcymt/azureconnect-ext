param applicationName string
param environment string
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
  }
}

output acrName string = main.outputs.acrName
output acrLoginServer string = main.outputs.acrLoginServer
