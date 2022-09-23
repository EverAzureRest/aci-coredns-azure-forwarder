targetScope = 'resourceGroup'

param loadBalancerName string
param location string
param loadBalancerSubnetId string
param backendname1 string
param backendIP1 string
param backendname2 string
param backendIP2 string
/*param backendConfig array*/

resource loadBalancer 'Microsoft.Network/loadBalancers@2022-01-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
   frontendIPConfigurations: [
    {
      name: 'loadBalancerFrontEnd'
      properties: {
        subnet: {
          id: loadBalancerSubnetId
        }
        privateIPAllocationMethod: 'Dynamic'
      }
    }
   ]
   backendAddressPools: [
    {
      name: 'coreDNSGroup'
      properties: {
         loadBalancerBackendAddresses: [
           {
             name: backendname1
              properties: {
                 ipAddress:backendIP1
              }
           }
           {
            name: backendname2
            properties: {
              ipAddress: backendIP2
            }
           }
         ]
       }
      }
   ]
   probes: [
    {
    name: 'DNSPortProbe'
    properties: {
      port: 53
      protocol: 'Tcp' 
    }
    }
   ]
   loadBalancingRules: [
    {
      name: 'DNSRule'
      properties: {
        frontendIPConfiguration: {
          id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd')
        }
        frontendPort: 53
        backendPort: 53
        protocol: 'Udp'
        backendAddressPool: {
          id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'coreDNSGroup')
        }
        probe: {
          id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'DNSPortProbe')
        }
      }
    }
   ]
    }
  }

output loadBalancerIP string = loadBalancer.properties.frontendIPConfigurations[0].properties.privateIPAddress
