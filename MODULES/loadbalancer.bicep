// param lbName string = 'myLoadBalancer'
var location = resourceGroup().location
param namePrefix string
var nameSuffix = 'lb'
var Name = '${namePrefix}-${location}-${nameSuffix}'
param logAnalyticsWorkspaceId string

@description('Public IP for the Load Balancer')
module lbPip './pip.bicep' = {
  name: '${Name}-pip'
  scope: resourceGroup()
  params: {
    Name: Name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    skuName: 'Standard'
  }
}

@description('Load Balancer for the VMs')
resource loadBalancer 'Microsoft.Network/loadBalancers@2024-01-01' = {
  name: Name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontendConfig'
        properties: {
          publicIPAddress: {
            id: lbPip.outputs.pipId
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    loadBalancingRules: [
      {
        name: 'httpRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', Name, 'frontendConfig')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', Name, 'backendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', Name, 'httpProbe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
        }
      }
    ]
    probes: [
      {
        name: 'httpProbe'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

// resource nic1 'Microsoft.Network/networkInterfaces@2021-02-01' = {
//   name: '${vm1Name}-nic'
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig1'
//         properties: {
//           subnet: {
//             id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
//           }
//           loadBalancerBackendAddressPools: [
//             {
//               id: loadBalancer.properties.backendAddressPools[0].id
//             }
//           ]
//         }
//       }
//     ]
//   }
// }

// resource nic2 'Microsoft.Network/networkInterfaces@2021-02-01' = {
//   name: '${vm2Name}-nic'
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig1'
//         properties: {
//           subnet: {
//             id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
//           }
//           loadBalancerBackendAddressPools: [
//             {
//               id: loadBalancer.properties.backendAddressPools[0].id
//             }
//           ]
//         }
//       }
//     ]
//   }
// }

// resource vm1 'Microsoft.Compute/virtualMachines@2021-03-01' = {
//   name: vm1Name
//   location: location
//   properties: {
//     hardwareProfile: {
//       vmSize: 'Standard_DS1_v2'
//     }
//     osProfile: {
//       computerName: vm1Name
//       adminUsername: 'azureuser'
//       adminPassword: 'P@ssw0rd1234!'
//     }
//     networkProfile: {
//       networkInterfaces: [
//         {
//           id: nic1.id
//         }
//       ]
//     }
//     storageProfile: {
//       imageReference: {
//         publisher: 'Canonical'
//         offer: 'UbuntuServer'
//         sku: '18.04-LTS'
//         version: 'latest'
//       }
//       osDisk: {
//         createOption: 'FromImage'
//       }
//     }
//   }
// }

// resource vm2 'Microsoft.Compute/virtualMachines@2021-03-01' = {
//   name: vm2Name
//   location: location
//   properties: {
//     hardwareProfile: {
//       vmSize: 'Standard_DS1_v2'
//     }
//     osProfile: {
//       computerName: vm2Name
//       adminUsername: 'azureuser'
//       adminPassword: 'P@ssw0rd1234!'
//     }
//     networkProfile: {
//       networkInterfaces: [
//         {
//           id: nic2.id
//         }
//       ]
//     }
//     storageProfile: {
//       imageReference: {
//         publisher: 'Canonical'
//         offer: 'UbuntuServer'
//         sku: '18.04-LTS'
//         version: 'latest'
//       }
//       osDisk: {
//         createOption: 'FromImage'
//       }
//     }
//   }
// }
