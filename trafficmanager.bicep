// Define the Traffic Manager profile
resource trafficManager 'Microsoft.Network/trafficManagerProfiles@2018-04-01' = {
  name: 'myTrafficManagerProfile'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Priority'
    dnsConfig: {
      relativeName: 'mytrafficmanager'
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
          target: 'vm1.region1.cloudapp.azure.com'
          endpointStatus: 'Enabled'
          priority: 1
        }
      }
      {
        name: 'endpoint2'
        type: 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'
        properties: {
          target: 'vm2.region2.cloudapp.azure.com'
          endpointStatus: 'Enabled'
          priority: 2
        }
      }
    ]
  }
}
