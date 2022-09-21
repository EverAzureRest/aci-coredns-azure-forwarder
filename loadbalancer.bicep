targetScope = 'resourceGroup'

param loadBalancerName string
param location string
param loadBalancerSubnetId string
param backendConfig array = []

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
         loadBalancerBackendAddresses:  backendConfig
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
          id: resourceId('Microsoft.Network/loadBalancers', loadBalancerName, '/frontendIPConfigurations/LoadBalancerFrontEnd')
        }
        frontendPort: 53
        backendPort: 53
        protocol: 'Udp'
        backendAddressPool: {
          id: resourceId('Microsoft.Network/loadBalancers', loadBalancerName, '/backendAddressPools/coreDNSGroup')
        }
        probe: {
          id: resourceId('Microsoft.Network/loadBalancers', loadBalancerName, '/probes/DNSPortProbe')
        }
      }
    }
   ]
    }
  }

output loadBalancerIP string = loadBalancer.properties.frontendIPConfigurations[0].properties.privateIPAddress
