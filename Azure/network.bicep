targetScope = 'resourceGroup'

param vnet1Name string
param vnet1Prefix string
param vnet2Name string
param vnet2Prefix string
param loadBalancerSubnetName string
param loadBalancerSubnetPrefix string
param DNSsubnetPrefix string
param DNSsubnetName string
param VMSubnetName string
param VMSubnetPrefix string
param AzureBastionSubnetPrefix string
param location string

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
        name: loadBalancerSubnetName
        properties: {
          addressPrefix: loadBalancerSubnetPrefix
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


output CoreDNSsubnetId string = vnet2.properties.subnets[0].id
output VMSubnetId string = vnet1.properties.subnets[1].id
output BastionSubnetId string = vnet1.properties.subnets[0].id
output loadBalancerSubnetId string = vnet2.properties.subnets[1].id
