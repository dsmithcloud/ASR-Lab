// Parameters & variables
@description('VM Name, Location and DNS Label Prefix')
param vmName string
param location string
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

// Resources
@description('Public IP address')
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

// Output
@description('Output the public IP ID & FQDN')
output pipId string = pip.id
output pipFqdn string = pip.properties.dnsSettings.fqdn
