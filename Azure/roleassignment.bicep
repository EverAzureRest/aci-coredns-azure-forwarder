param principalId string
param automationAccountId string

var roleDefinitionId = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(automationAccountId, resourceGroup().id, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}
