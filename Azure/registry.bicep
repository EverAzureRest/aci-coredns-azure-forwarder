targetScope = 'resourceGroup'

param containerRegistryName string
param registrySku string 
param location string 
param dockerSourceRepo string
param branch string
param imageName string
param imageVersion string

resource registry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: registrySku
  }
  properties: {
    adminUserEnabled: true
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Enabled'
  }
}

resource quickBuild 'Microsoft.ContainerRegistry/registries/taskRuns@2019-06-01-preview' = {
  name: 'quickBuild'
  parent: registry
  location: location
  properties: {
    runRequest: {
      type: 'DockerBuildRequest'
      platform: {
        os: 'Linux'
      }
      dockerFilePath: 'Dockerfile'
      sourceLocation: '${dockerSourceRepo}#${branch}:Docker'
      imageNames: [
        '${registry.properties.loginServer}/${imageName}:${imageVersion}'
      ]
      isPushEnabled: true
    }
  }
}

output image string = quickBuild.properties.runRequest.imageNames[0]
output registryName string = registry.name
