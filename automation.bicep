// Parameters & variables
@description('Automation Account Name & Location')
param vaultName string
param location string

// Resources
@description('Automation Account')
resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: vaultName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

// Output
@description('Output the automation account ID')
output automationAccountId string = automationAccount.id
