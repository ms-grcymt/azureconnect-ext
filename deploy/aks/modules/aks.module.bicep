// parameters 
// description('The DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = 'cl01'

// description('The name of the Managed Cluster resource.')
param clusterName string = 'aks101'

// description('Specifies the Azure location where the cluster should be created.')
param location string = resourceGroup().location

// minValue(1), maxValue(50)
// description('The number of nodes for the cluster. 1 Node is enough for Dev/Test and minimum 3 nodes, is recommended for Production')
param systemNodeCount int = 1
param workerNodeCount int = 1

// description('The size of the Virtual Machine.')
param systemNodeVMSize string = 'Standard_D2s_v3'
param workerNodeVMSize string = 'Standard_D2s_v3'

// The nodes' VNET & subnet ID
param subnetID string

// The nodes resource group name
param nodeResourceGroup string = '${dnsPrefix}-${clusterName}-rg'

param tags object = {
  environment: 'production'
  projectCode: 'xyz'
}

param isAksPrivate bool

// vars
var systemNodePoolName = 'systempool'
var workerNodePoolName = 'workerpool'
var aksLawsName = '${resourceGroup().name}-laws-${uniqueString(resourceGroup().id)}'

// resources
resource aks_workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: aksLawsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Create AKS MAnaged Identity
resource aksUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${clusterName}-mi'
  location: resourceGroup().location  
}

// Create the Azure kubernetes service cluster
resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksUserDefinedManagedIdentity.id}' : {}
    }
  }
  properties: {
    enableRBAC: true
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: systemNodePoolName
        count: systemNodeCount
        mode: 'System'
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        vmSize: systemNodeVMSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: false
        vnetSubnetID: subnetID
      }
      {
        name: workerNodePoolName
        count: workerNodeCount
        mode: 'User'
        vmSize: workerNodeVMSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: false
        vnetSubnetID: subnetID
      }
    ]
    apiServerAccessProfile: {
      enablePrivateCluster: isAksPrivate
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    nodeResourceGroup: nodeResourceGroup
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: aks_workspace.id
        }
        enabled: true
      }
    }
  }
}

output aksid string = aks.id
output apiServerAddress string = isAksPrivate ? aks.properties.privateFQDN : ''
output aksnodesrg string = aks.properties.nodeResourceGroup
output aksclientid string = aks.properties.servicePrincipalProfile.clientId
