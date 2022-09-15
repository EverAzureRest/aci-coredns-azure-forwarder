targetScope = 'resourceGroup'

param containerGroupName string

param numberOfInstances int = 2

param image string = 'coredns/coredns'

param cpuRequest int

param memRequest int

param gitRepoUrl string

@description('Name of the existing VNET to deploy the DNS Fowarder to')
param vnetName string

@description('Name of the Resource Group that the VNET resides in')
param vnetRGName string

param subnetName string

param subnetPrefix string

param loadBalancerName string

param deploymentLocation string = resourceGroup().location

module network 'network.bicep' = {
  name: 'NetworkDeployment'
  scope: resourceGroup(vnetRGName)
  params: {
    vnetName: vnetName
    subnetName: subnetName
    subnetPrefix: subnetPrefix
  }
}


resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = [for i in range(0, numberOfInstances): {
  name: 'containerDeployment-${i}'
  location: deploymentLocation
  properties: {
     containers: [
      {
        name: '${containerGroupName}${i}'
        properties: {
          image: image
          resources: {
            requests: {
              cpu: cpuRequest
              memoryInGB: memRequest
            }
          }
          ports: [
            {
              port: 53
              protocol: 'UDP'
            }
          ]
          volumeMounts: [
            {
              name: 'config'
              mountPath: '/'
            }
          ]
        }
      }
      ]
    osType: 'Linux'
    subnetIds: [
      {
        id: network.outputs.subnetId
      }
    ]
    volumes: [
      {
        name: 'config'
        gitRepo: {
          repository: gitRepoUrl
        }
      }
    ]
  }
}]



resource loadBalancer 'Microsoft.Network/loadBalancers@2022-01-01' = {
  name: loadBalancerName
  location: deploymentLocation
  dependsOn: containerGroup
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
   backendAddressPools: [
    {
      name: 'coreDNSGroup'
      properties: {
         loadBalancerBackendAddresses:  [
           {
             name: containerGroup[0].name
             properties: {
              
               ipAddress: containerGroup[0].properties.ipAddress.ip
             }
           }
           {
            name: containerGroup[1].name
            properties: {
              ipAddress: containerGroup[1].properties.ipAddress.ip
            }
           }
         ]
       }
      }
   ]
    }
  }

output LoadBalancerIP array = loadBalancer.properties.frontendIPConfigurations
