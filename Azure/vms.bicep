targetScope = 'resourceGroup'

param DCVMName string
param DCPrivateIP string
param DCSubnetID string
param location string
param automationAccountName string
param domainUsername string
@secure()
param vmPassword string
param testVMName string
param vmSubnetId string

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' existing = {
  name: automationAccountName
  scope: resourceGroup()
}

var registrationUrl = reference(resourceId('Microsoft.Automation/automationAccounts', automationAccountName), '2015-10-31').registrationUrl

resource DCNic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: '${DCVMName}-nic'
  location: location
  properties: {
   ipConfigurations: [
    {
      name: '${DCVMName}-ipconfig'
       properties: {
         privateIPAddress: DCPrivateIP
         privateIPAllocationMethod: 'Static'
         subnet: {
           id: DCSubnetID
         }
       } 
    }
   ]
  }
}

resource testVMnic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: '${testVMName}-nic'
  location: location
  properties: {
    ipConfigurations: [
       {
        name: '${testVMName}-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetId
          }
        }
       }
    ]
  }
}

resource DCVM 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: DCVMName
  location: location
  properties: {
   hardwareProfile: {
     vmSize: 'Standard_D2_v3'
   }
   osProfile: {
    computerName: DCVMName
    adminUsername: domainUsername
    adminPassword: vmPassword
   }
   storageProfile: {
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
    osDisk: {
      createOption: 'FromImage'
    }
    dataDisks: [
      {
       createOption: 'Empty'
       lun: 0
       caching: 'None'
       diskSizeGB: 50
      }
    ]
   }
   networkProfile: {
      networkInterfaces: [
         {
           id: DCNic.id
         }
      ]
    }
  }
  resource dscExtension 'extensions@2022-03-01' = {
    name: 'OnboardtoDSC'
    location: location
    properties: {
      type: 'DSC'
      publisher: 'Microsoft.PowerShell'
      typeHandlerVersion: '2.77'
      autoUpgradeMinorVersion: true
      protectedSettings: {
        Items: {
          registrationKeyPrivate: automationAccount.listKeys().keys[0].Value
        }
      }
      settings: {
        Properties: [
          {
            Name: 'RegistrationKey'
            Value: {
              UserName: 'PLACEHOLDER_DONOTUSE'
              Password: 'PrivateSettingsRef:registrationKeyPrivate'
            }
            TypeName: 'System.Management.Automation.PSCredential'
          }
          {
            Name: 'RegistrationUrl'
            Value: registrationUrl
            TypeName: 'System.String'
          }
          {
            Name: 'NodeConfigurationName'
            Value: 'Domain.localhost'
            TypeName: 'System.String'
          }
          {
            Name: 'ConfigurationMode'
            Value: 'ApplyandAutoCorrect'
            TypeName: 'System.String'
          }
          {
            Name: 'RebootNodeIfNeeded'
            Value: true
            TypeName: 'System.Boolean'
          }
          {
            Name: 'ActionAfterReboot'
            Value: 'ContinueConfiguration'
            TypeName: 'System.String'
          }
        ]
      }
    }
  }
}

resource testVM 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: testVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2_v3'
    }
    osProfile: {
     adminUsername: domainUsername
     adminPassword: vmPassword
     computerName: testVMName
    }
    storageProfile: {
       osDisk: {
        createOption: 'FromImage'
       }
       imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2019-Datacenter'
          version: 'latest'
        }
    }
    networkProfile: {
      networkInterfaces: [
         {
          id: testVMnic.id
         }
      ]
    }
  }
}

