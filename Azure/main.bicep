targetScope = 'resourceGroup'

param containerGroupName string
param numberOfInstances int = 2
param cpuRequest int
param memRequest int
param gitRepoUrl string = 'https://github.com/EverAzureRest/aci-coredns-azure-forwarder.git'
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
param privateEndpointSubnetName string
param privateEndpointSubnetPrefix string
param automationAccountName string
@description('FQDN of the AD Domain i.e. contoso.com')
param domainName string
@secure()
param domainPassword string
param domainUser string
param dscremotepath string = 'https://raw.githubusercontent.com/EverAzureRest/aci-coredns-azure-forwarder/main/DSC/domain.ps1'
param domainControllerName string
param domainControllerPrivateIP string
param domainControllerSubnetName string
param domainControllerSubnetPrefix string
param testVMName string
/* by default, we will deploy to the location tag on the Resource Group */
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
    privateEndpointSubnetName: privateEndpointSubnetName
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
    location: deploymentLocation
    DCPrivateIP: domainControllerPrivateIP
    domainControllerSubnetName: domainControllerSubnetName
    domainControllerSubnetPrefix: domainControllerSubnetPrefix
  }
}

module storage 'storage.bicep' = {
  name: 'StorageDeployment'
  params: {
    deploymentLocation: deploymentLocation
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    vnetId: network.outputs.vnetId
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

module automation 'automation.bicep' = {
  name: 'automationAccountDeployment'
  params: {
    automationAccountName: automationAccountName
    location: deploymentLocation
    domainName: domainName
    domainPassword: domainPassword
    domainUser: domainUser
    dscremotepath: dscremotepath
    forwarderIPs: [for i in range(0, numberOfInstances): containerGroupDeployment[i].outputs.containerIp]
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
   testVMName: testVMName
   vmSubnetId: network.outputs.VMSubnetId
  }
}
