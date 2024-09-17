// Parameters & variables
@description('Automation Account Name & Location')
param vaultName string
param location string
param logAnalyticsWorkspaceId string

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

// Define the Diagnostic Settings for the Automation Account
resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${automationAccount.name}-diag'
  scope: automationAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
      {
        category: 'DscNodeStatus'
        enabled: true
      }
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Output
@description('Output the automation account ID')
output automationAccountId string = automationAccount.id
