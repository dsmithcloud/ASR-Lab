// Parameters & variables
@description('Virtual Network Name, Location, Address Space and Subnets')
param name string
param location string
param addressSpace object
param subnets array

// Resources
@description('Virtual Network')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: name
  location: location
  properties: {
    addressSpace: addressSpace
    subnets: subnets
  }
}

// Output
@description('Output the virtual network ID & subnets')
output vnetId string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
