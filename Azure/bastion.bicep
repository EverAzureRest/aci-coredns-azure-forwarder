targetScope = 'resourceGroup'

param location string

param BastionSubnetId string

var bastionName = '${toLower(uniqueString(resourceGroup().id))}-bastion'
var publicIPName = '${bastionName}-pip'

resource publicIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConfig1'
        properties: {
          subnet: {
            id: BastionSubnetId
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}
