param vmName string
param location string
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

resource pip 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: '${location}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

output pipId string = pip.id
output pipFqdn string = pip.properties.dnsSettings.fqdn
