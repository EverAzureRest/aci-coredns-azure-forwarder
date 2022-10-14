targetScope = 'resourceGroup'

param vnet1Name string
param vnet1Prefix string
param vnet2Name string
param vnet2Prefix string
param privateEndpointSubnetName string
param privateEndpointSubnetPrefix string
param DNSsubnetPrefix string
param DNSsubnetName string
param VMSubnetName string
param VMSubnetPrefix string
param AzureBastionSubnetPrefix string
param DCPrivateIP string
param location string
param domainControllerSubnetName string
param domainControllerSubnetPrefix string

var delegationName = 'aciVnetDelegation'

resource vnet1 'Microsoft.Network/virtualnetworks@2022-01-01' = {
  name: vnet1Name
  location: location
  properties: {
     addressSpace: {
       addressPrefixes: [
        vnet1Prefix
       ]
     }
     dhcpOptions: {
      dnsServers: [
        DCPrivateIP
      ]
     }
     subnets: [
       {
         name: 'AzureBastionSubnet'
         properties: {
          addressPrefix: AzureBastionSubnetPrefix
         }
       }
       {
        name: VMSubnetName
        properties: {
          addressPrefix: VMSubnetPrefix
        }
       }
     ]
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet2Prefix
      ]
    }
    subnets: [
      {
        name: DNSsubnetName
        properties: {
          addressPrefix: DNSsubnetPrefix
          delegations: [
            {
              name: delegationName
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
        }
      }
      {
        name: domainControllerSubnetName
        properties: {
          addressPrefix: domainControllerSubnetPrefix
        }
      }
    ]
  }
}

resource peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  name: 'vnet1-to-vnet2'
  parent: vnet1 
  dependsOn: [
  ]
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
       id: vnet2.id
    }
  }
}

resource peer2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  name: 'vnet2-to-vnet1'
  parent: vnet2
  properties: {
   peeringState: 'Connected'
   remoteVirtualNetwork: {
    id: vnet1.id
   } 
  }
}


output CoreDNSsubnetId string = vnet2.properties.subnets[0].id
output VMSubnetId string = vnet1.properties.subnets[1].id
output BastionSubnetId string = vnet1.properties.subnets[0].id
output privateEndpointSubnetId string = vnet2.properties.subnets[1].id
output dcSubnetId string = vnet2.properties.subnets[2].id
output vnetId string = vnet2.id
