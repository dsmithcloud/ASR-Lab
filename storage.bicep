param name string
param location string
param sku object
var uniqueName = '${name}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: toLower(uniqueName)
  location: location
  sku: sku
  kind: 'StorageV2'
}
