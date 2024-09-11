@description('Log Analytics Name, Location and SKU')
param name string
param location string
param sku object = {
  name: 'PerGB2018'
}
param retentionInDays int = 30
var uniqueName = '${name}${uniqueString(resourceGroup().id)}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: uniqueName
  location: location
  properties: {
    sku: sku
    retentionInDays: retentionInDays
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
