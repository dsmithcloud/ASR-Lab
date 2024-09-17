// Parameters & variables
@description('Traffic Manager Profile Name, Endpoint 1 Target, Endpoint 2 Target')
param endpoint1Target string
param endpoint2Target string
param profileName string
param logAnalyticsWorkspaceId string
var tmName = '${profileName}${uniqueString(resourceGroup().id)}'

//Resources
@description('Traffic Manager Profile')
resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: tmName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Priority'
    dnsConfig: {
      relativeName: tmName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'TCP'
      port: 80 // http port
      path: null
    }
    endpoints: [
      {
        name: 'vmEndpt1'
        type: 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'
        properties: {
          target: endpoint1Target
          endpointStatus: 'Enabled'
          priority: 1
        }
      }
      {
        name: 'vmEndpt2'
        type: 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'
        properties: {
          target: endpoint2Target
          endpointStatus: 'Enabled'
          priority: 2
        }
      }
    ]
  }
}

// Define the Diagnostic Settings for the Traffic Manager
resource trafficManagerDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'trafficManagerDiagSettings'
  scope: trafficManager
  properties: {
    logs: [
      {
        category: 'ProbeHealthStatusEvents'
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

//Output
@description('Output the Traffic Manager ID & FQDN')
output trafficManagerId string = trafficManager.id
output trafficManagerfqdn string = trafficManager.properties.dnsConfig.fqdn
