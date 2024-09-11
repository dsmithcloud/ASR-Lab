// Parameters & variables
@description('VM Name, Location and DNS Label Prefix')
param vmName string
param location string
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')
param logAnalyticsWorkspaceId string

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

// Define the Diagnostic Settings for the Public IP
resource publicIPDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${pip.name}-diag'
  scope: pip
  properties: {
    logs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: true
      }
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: true
      }
      {
        category: 'DDoSMitigationReports'
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

// Output
@description('Output the public IP ID & FQDN')
output pipId string = pip.id
output pipFqdn string = pip.properties.dnsSettings.fqdn
