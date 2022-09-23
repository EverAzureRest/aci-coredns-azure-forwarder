targetScope = 'resourceGroup'

param containerGroupName string
param location string
param image string
param cpuRequest int
param memRequest int
param subnetId string
param containerRegistryName string

resource registryServer 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: containerGroupName
  location: location
  properties: {
     containers: [
      {
        name: containerGroupName
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
        }
      }
     ]
    imageRegistryCredentials: [
      {
        server: registryServer.properties.loginServer
        password: registryServer.listCredentials().passwords[0].value
        username: registryServer.name
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Private'
      ports: [
        {
          port: 53
          protocol: 'UDP'
        }
      ]
    }
    subnetIds: [
      {
        id: subnetId
      }
    ]
    restartPolicy: 'OnFailure'
  }
}

output containerIp string = containerGroup.properties.ipAddress.ip
output containerName string = containerGroup.name
