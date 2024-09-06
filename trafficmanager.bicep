// Parameters & variables
@description('Traffic Manager Profile Name, Endpoint 1 Target, Endpoint 2 Target')
param endpoint1Target string
param endpoint2Target string
param profileName string

//Resources
@description('Traffic Manager Profile')
resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
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

//Output
@description('Output the Traffic Manager ID')
output trafficManagerId string = trafficManager.id
