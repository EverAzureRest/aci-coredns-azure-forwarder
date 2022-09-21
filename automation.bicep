targetScope = 'resourceGroup'

param automationAccountName string
param location string
param gitReporUrl string
param domainName string
param domainUser string
@secure()
param domainPassword string

var xadmoduleuri = 'https://devopsgallerystorage.${environment().suffixes.storage}/packages/xactivedirectory.3.0.0.nupkg'
var xstoragemoduleuri = 'https://devopsgallerystorage.${environment().suffixes.storage}/packages/xstorage.3.4.0.0.nupkg'
var xpendingrebooturi = 'https://devopsgallerystorage.${environment().suffixes.storage}/packages/xpendingreboot.0.4.0.0.nupkg'

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    disableLocalAuth: true
    sku: {
      name: 'Basic'
    }
  }
}

resource domainDSC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: 'ADDomainDSC'
  parent: automationAccount
  properties: {
    source: {
     type: 'uri'
     value: '${gitReporUrl}/DSC/domain.ps1'
    }
  }
}

resource domainCred 'Microsoft.Automation/automationAccounts/credentials@2020-01-13-preview' = {
  name: 'domainCredential'
  parent: automationAccount
  properties: {
    password: domainPassword
    userName: domainUser
  }
}

resource ADModule 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'xActiveDirectory'
  parent: automationAccount
  properties: {
    contentLink: {
       uri: xadmoduleuri
    }
  }
}

resource storageModule 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'xStorage'
  parent: automationAccount
  properties: {
    contentLink: {
      uri: xstoragemoduleuri
    }
  }
}

resource rebootModule 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'xPendingReboot'
  parent: automationAccount
  properties: {
    contentLink: {
      uri: xpendingrebooturi
    }
  }
}

resource dscCompile 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: 'compileDSC'
  parent: automationAccount
  properties: {
    configuration: {
      name: 'Domain'
    }
    parameters: {
      domainName: domainName
    }
  }
}
