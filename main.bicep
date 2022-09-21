targetScope = 'resourceGroup'

param containerGroupName string
param numberOfInstances int = 2
param image string = 'coredns/coredns'
param cpuRequest int
param memRequest int
param gitRepoUrl string
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
/*
module VMs 'vms.bicep' = {
  name: 'VMDeployment'
  scope: resourceGroup()
  params:{
    
  }
}
*/
module containerGroupDeployment 'containers.bicep' = [for i in range (0, numberOfInstances): {
  name: 'containerDeployment-${i}'
  scope: resourceGroup()
  params: {
    containerGroupName: '${containerGroupName}${i}'
    location: deploymentLocation
    image: image
    cpuRequest: cpuRequest
    memRequest: memRequest
    subnetId: network.outputs.CoreDNSsubnetId
    gitRepoUrl: gitRepoUrl
  }
}]

module loadBalancer 'loadbalancer.bicep' = {
  name: 'loadBalancerDeployment'
  dependsOn: containerGroupDeployment
  params: {
    loadBalancerName: loadBalancerName
    loadBalancerSubnetId: network.outputs.loadBalancerSubnetId
    location: deploymentLocation
    backendConfig: [for i in range(0, numberOfInstances): [
      {
        name: containerGroupDeployment[i].outputs.containerName
        properties: {
          ipAddress: containerGroupDeployment[i].outputs.containerIp
        }
      }
    ]]
  }
}

module automation 'automation.bicep' = {
  name: 'automationAccountDeployment'
  params: {
    automationAccountName: automationAccountName
    location: deploymentLocation
    gitReporUrl: gitRepoUrl
    domainName: domainName
    domainPassword: domainPassword
    domainUser: domainUser
  }
}

