// Parameters & variables
@description('Virtual Network Name, Location, Address Space and Subnets')
param name string
param location string
param addressSpace object
param subnets array
param logAnalyticsWorkspaceId string

// Resources
@description('Virtual Network')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: name
  location: location
  properties: {
    addressSpace: addressSpace
  }
}
// Subnets
resource subnetLoop 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = [
  for subnet in subnets: {
    name: subnet.name
    parent: virtualNetwork
    properties: {
      addressPrefix: subnet.properties.addressPrefix
    }
  }
]

// Define the Diagnostic Settings for the VNet
resource vnetDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${virtualNetwork.name}-diag'
  scope: virtualNetwork
  properties: {
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

// // Network Watcher
// resource networkWatcher 'Microsoft.Network/networkWatchers@2024-01-01' = {
//   name: 'NetworkWatcher_${location}'
//   location: location
//   properties: {}
// }

// Output
@description('Output the virtual network ID & subnets')
output vnetId string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
output name string = virtualNetwork.name
