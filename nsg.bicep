// Parameters & variables
@description('VM Name, Location and my IP address')
param vmName string
param location string
param myIp string

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
        name: 'Allow-RDP-From-Specific-IP'
        properties: {
          priority: 1001
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: myIp
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

// Output
@description('Output the NSG ID')
output nsgId string = nsg.id
