param vaultName string
param location string

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
