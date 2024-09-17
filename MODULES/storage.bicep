// Parameters & variables
@description('Storage Account Name, Location and SKU')
param name string
param location string
param sku object
param logAnalyticsWorkspaceId string
var uniqueName = '${name}${uniqueString(resourceGroup().id)}'
var logSettings = [
  {
    category: 'StorageRead'
    enabled: true
  }
  {
    category: 'StorageWrite'
    enabled: true
  }
  {
    category: 'StorageDelete'
    enabled: true
  }
]

// Resources
@description('Storage account')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower(uniqueName)
  location: location
  sku: sku
  kind: 'StorageV2'
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccount.name}-diagnostic'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    storageAccountId: storageAccount.id
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource diagnosticSettingsBlob 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccount.name}-blob-diag'
  scope: blobService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logSettings
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource diagnosticsFile 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: fileService
  name: '${storageAccount.name}-file-diag'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logSettings
  }
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource diagnosticsQueue 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: queueService
  name: '${storageAccount.name}-queue-diag'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logSettings
  }
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource diagnosticsTable 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: tableService
  name: '${storageAccount.name}-table-diag'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logSettings
  }
}

// Output
@description('Output the storage account ID')
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
