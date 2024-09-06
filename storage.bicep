// Parameters & variables
@description('Storage Account Name, Location and SKU')
param name string
param location string
param sku object
var uniqueName = '${name}${uniqueString(resourceGroup().id)}'

// Resources
@description('Storage account')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower(uniqueName)
  location: location
  sku: sku
  kind: 'StorageV2'
}

// Output
@description('Output the storage account ID')
output storageAccountId string = storageAccount.id
