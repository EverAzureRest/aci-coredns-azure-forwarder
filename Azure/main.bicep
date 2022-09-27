targetScope = 'resourceGroup'

param containerGroupName string
param numberOfInstances int = 2
param cpuRequest int
param memRequest int
param gitRepoUrl string
@description('Branch name for the Docker build reference in the repository')
param gitBranch string
param imageName string
@description('Name of the VNET to deploy the DNS Fowarder to')
param vnet1Name string
param vnet1Prefix string
param vnet2Name string
param vnet2Prefix string
@description('Name of the subnet where the CoreDNS containers will reside')
param DNSsubnetName string
param DNSsubnetPrefix string
param VMSubnetName string
param VMSubnetPrefix string
param AzureBastionSubnetPrefix string
param loadBalancerName string
param loadBalancerSubnetName string
param loadBalancerSubnetPrefix string
param automationAccountName string
@description('FQDN of the AD Domain i.e. contoso.com')
param domainName string
@secure()
param domainPassword string
param domainUser string
param dscremotepath string
param domainControllerName string
param domainControllerPrivateIP string
param domainControllerSubnetName string
param domainControllerSubnetPrefix string
param deploymentLocation string = resourceGroup().location

module network 'network.bicep' = {
  name: 'NetworkDeployment'
  scope: resourceGroup()
  params: {
    vnet1Name: vnet1Name
    vnet1Prefix: vnet1Prefix
    vnet2Name: vnet2Name
    vnet2Prefix: vnet2Prefix
    DNSsubnetName: DNSsubnetName
    DNSsubnetPrefix: DNSsubnetPrefix
    VMSubnetName: VMSubnetName
    VMSubnetPrefix: VMSubnetPrefix
    AzureBastionSubnetPrefix: AzureBastionSubnetPrefix
    loadBalancerSubnetName: loadBalancerSubnetName
    loadBalancerSubnetPrefix: loadBalancerSubnetPrefix
    location: deploymentLocation
    DCPrivateIP: domainControllerPrivateIP
    domainControllerSubnetName: domainControllerSubnetName
    domainControllerSubnetPrefix: domainControllerSubnetPrefix
  }
}

module Bastion 'bastion.bicep' = {
  name: 'BastionDeployment'
  scope: resourceGroup()
  params:{
    location: deploymentLocation
    BastionSubnetId: network.outputs.BastionSubnetId
  }
}

module registry 'registry.bicep' = {
  name: 'registryDeployment'
  params: {
    branch: gitBranch
    containerRegistryName: '${uniqueString(resourceGroup().id)}registry'
    dockerSourceRepo: gitRepoUrl
    imageName: imageName
    imageVersion: 'latest'
    location: deploymentLocation
    registrySku: 'Basic'
  }
}

module containerGroupDeployment 'containers.bicep' = [for i in range (0, numberOfInstances): {
  name: 'containerDeployment-${i}'
  scope: resourceGroup()
  params: {
    containerGroupName: '${containerGroupName}${i}'
    location: deploymentLocation
    image: registry.outputs.image
    cpuRequest: cpuRequest
    memRequest: memRequest
    subnetId: network.outputs.CoreDNSsubnetId
    containerRegistryName: registry.outputs.registryName
  }
}]

module loadBalancer 'loadbalancer.bicep' = {
  name: 'loadBalancerDeployment'
  dependsOn: containerGroupDeployment
  params: {
    loadBalancerName: loadBalancerName
    loadBalancerSubnetId: network.outputs.loadBalancerSubnetId
    location: deploymentLocation
    /*backendConfig: [for i in range(0, numberOfInstances): [
      {
        backendName: containerGroupDeployment[i].outputs.containerName
        backendIP: containerGroupDeployment[i].outputs.containerIp
      }
    ]]
    Bicep will NOT accept an array format for the back end configuration of the load balancer, so is forcing me to do stupid things 
    here to deal with the output arrays*/
    backendname1: containerGroupDeployment[0].outputs.containerName
    backendIP1: containerGroupDeployment[0].outputs.containerIp
    backendname2: containerGroupDeployment[1].outputs.containerName
    backendIP2: containerGroupDeployment[1].outputs.containerIp
  }
}

module automation 'automation.bicep' = {
  name: 'automationAccountDeployment'
  params: {
    automationAccountName: automationAccountName
    location: deploymentLocation
    domainName: domainName
    domainPassword: domainPassword
    domainUser: domainUser
    dscremotepath: dscremotepath
    forwarderIP: loadBalancer.outputs.loadBalancerIP
  }
}

module roleAssignment 'roleassignment.bicep' = {
  name: 'roleAssignment'
  params: {
    automationAccountId: automation.outputs.automationAccountId
    principalId: automation.outputs.principalId
  }
}

module VMs 'vms.bicep' = {
  name: 'VMDeployment'
  scope: resourceGroup()
  params:{
   DCVMName: domainControllerName
   automationAccountName: automation.outputs.automationAccountName
   DCPrivateIP: domainControllerPrivateIP
   location: deploymentLocation
   DCSubnetID: network.outputs.dcSubnetId
   domainUsername: domainUser
   vmPassword: domainPassword
  }
}
