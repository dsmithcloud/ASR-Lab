// Parameters & variables
@description('VM Name, Location and my IP address')
param vmName string
param location string
param logAnalyticsWorkspaceId string

// Resources
@description('Network Security Group and rules')
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: '${vmName}-${location}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-From-Specific-IP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-Internet-Outbound'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
  }
}

// Define the Diagnostic Settings for the NSG
resource nsgDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${nsg.name}-diag'
  scope: nsg
  properties: {
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
    metrics: []
    workspaceId: logAnalyticsWorkspaceId
  }
}

// Output
@description('Output the NSG ID')
output nsgId string = nsg.id
