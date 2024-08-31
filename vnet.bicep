param name string
param location string
param addressSpace object
param subnets array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  properties: {
    addressSpace: addressSpace
    subnets: subnets
  }
}

output vnetId string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
