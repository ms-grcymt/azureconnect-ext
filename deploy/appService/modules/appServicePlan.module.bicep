param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'S1'
  'S2'
  'S3'
  'P1v3'
  'P2v3'
  'P3v3'
])
param skuName string = 'P1v3'

var skuTier =  substring(skuName, 0, 1) == 'S' ? 'Standard' : 'PremiumV3'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'app,linux'
  properties: {
    reserved: true
  }
}

output id string = appServicePlan.id
output name string = name
