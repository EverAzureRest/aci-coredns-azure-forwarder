targetScope = 'resourceGroup'

param containerGroupName string
param location string
param image string
param cpuRequest int
param memRequest int
param subnetId string
param gitRepoUrl string

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
        id: subnetId
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
}

output containerIp string = containerGroup.properties.ipAddress.ip
output containerName string = containerGroup.name
