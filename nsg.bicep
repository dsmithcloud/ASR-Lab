param vmName string
param location string
param myIp string

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${vmName}-${location}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-Specific-IP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: myIp
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
