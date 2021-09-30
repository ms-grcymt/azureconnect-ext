param naming object
param location string = resourceGroup().location
param tags object

var resourceNames = {
  vnet: naming.virtualNetwork.name
  subnet: naming.subnet.name
  aks: naming.kubernetesCluster.name
}

// Create the aks vnet
module aksvnet './modules/vnet.module.bicep' = {
  name: 'aksVnetDeployment'
  params: {
    tags: tags
    location: location
    vnetName: resourceNames.vnet
    vnetPrefix: '192.168.4.0/22'
    subnets: [
      {
        name: '${resourceNames.subnet}-nodes'
        subnetPrefix: '192.168.4.0/23'
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: '${resourceNames.subnet}-ingress'
        subnetPrefix: '192.168.6.0/24'
        privateEndpointNetworkPolicies: 'Enabled'
      }
    ]
  }
}

// Create the AKS Cluster
module aks 'modules/aks.module.bicep' = {
  name: 'aksDeployment'
  params: {
    location: location
    tags: tags
    dnsPrefix:resourceNames.aks
    nodeResourceGroup: 'rg-nodes-${resourceNames.aks}'
    clusterName: resourceNames.aks    
    isAksPrivate: false
    subnetID: aksvnet.outputs.subnet[0].subnetID
  }
}
