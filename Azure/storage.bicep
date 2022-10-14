targetScope = 'resourceGroup'

param deploymentLocation string
param privateEndpointSubnetId string
param vnetId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: '${uniqueString(resourceGroup().id)}storage'
  location: deploymentLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  } 
}

resource blobStorage 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  name: 'default'
  parent: storageAccount
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: '${uniqueString(resourceGroup().id)}endpoint'
  location: deploymentLocation
  properties: {
    subnet: {
      id: privateEndpointSubnetId 
    }
  privateLinkServiceConnections: [
   {
    id: ''
    name: 'blobPrivateConnection'
    properties: {
      privateLinkServiceId: storageAccount.id
      groupIds: [
        'blob'
      ]
    }
   }
  ]
  }
}


resource privateDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}

resource privateDNSLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${uniqueString(vnetId)}link'
  parent: privateDNS
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}


resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${privateEndpoint.name}/storage'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNS.id
        }
      }
    ]
  }
}
