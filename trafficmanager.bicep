param endpoint1Target string
param endpoint2Target string
param profileName string

// Define the Traffic Manager profile
resource trafficManager 'Microsoft.Network/trafficManagerProfiles@2018-04-01' = {
  name: profileName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Priority'
    dnsConfig: {
      relativeName: profileName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'TCP'
      port: 3389 // RDP port
      path: null
    }
    endpoints: [
      {
        name: 'endpoint1'
        type: 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'
        properties: {
          target: endpoint1Target
          endpointStatus: 'Enabled'
          priority: 1
        }
      }
      {
        name: 'endpoint2'
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
