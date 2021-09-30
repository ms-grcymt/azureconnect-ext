param naming object
param location string = resourceGroup().location
param tags object

var resourceNames = {
  acr: naming.containerRegistry.nameUnique
}

// Create the ACR
module acr 'modules/containerRegistry.module.bicep' = {
  name: 'acrDeployment'
  params: {
    tags: tags
    location: location
    name: resourceNames.acr
  }
}

output acrName string = resourceNames.acr
output acrLoginServer string = acr.outputs.loginServer
