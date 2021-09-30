param name string
param location string = resourceGroup().location
param tags object = {}

param subnetNamePrefix string
@description('This is expected be a /24 address space to correctly create the respective subnets')
param addressPrefix string
param includeBastion bool = true

var defaultSnet = {
  name: '${subnetNamePrefix}-default'
  properties: {
    addressPrefix: replace(addressPrefix, '.0/24', '.0/26')
  }
}

var appSnet = {
  name: '${subnetNamePrefix}-apps'
  properties: {
    addressPrefix: replace(addressPrefix, '.0/24', '.64/26')
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

var devOpsSnet = {
  name: '${subnetNamePrefix}-devops'
  properties: {
    addressPrefix: replace(addressPrefix, '.0/24', '.128/26')
  }
}

var integratedSnet = {
  name: '${subnetNamePrefix}-integration'
  properties: {
    addressPrefix: replace(addressPrefix, '.0/24', '.192/27')
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
  }
}

var bastionSnet = {
  name: 'AzureBastionSubnet'
  properties: {
    addressPrefix: replace(addressPrefix, '.0/24', '.224/27')
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

var subnetConfigs = includeBastion ? [
  defaultSnet
  appSnet
  devOpsSnet
  integratedSnet
  bastionSnet
] : [
  defaultSnet
  appSnet
  devOpsSnet
  integratedSnet
]

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnetConfigs
  }
  tags: tags
}

output vnetId string = vnet.id
output defaultSnetId string = vnet.properties.subnets[0].id
output appSnetId string = vnet.properties.subnets[1].id
output devOpsSnetId string = vnet.properties.subnets[2].id
output integratedSnetId string = vnet.properties.subnets[3].id
output bastionSnetId string = includeBastion ? vnet.properties.subnets[4].id : ''
