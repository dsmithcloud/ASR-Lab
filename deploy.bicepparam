using 'deploy.bicep'

// param subscriptionId = 'a59a1537-1278-4073-83d6-505e8200c8c9'
param parDeploymentPrefix = 'asrdemo'
param sourceLocation = 'uksouth'
param targetLocation = 'ukwest'
param vmAdminPassword = 'P@ssw0rd1234'
param sourceVnetConfig = {
  addressSpace: {
    addressPrefixes: [
      '10.0.0.0/16'
    ]
  }
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.0.0/24'
    }
    {
      name: 'AzureBastionSubnet'
      addressPrefix: '10.0.1.0/24'
    }
  ]
}
param targetVnetConfig = {
  addressSpace: {
    addressPrefixes: [
      '10.1.0.0/16'
    ]
  }
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.1.0.0/24'
    }
    {
      name: 'testfailover'
      addressPrefix: '10.1.1.0/24'
    }
  ]
}

// param sourceVmConfig = {
//   vmName: myVmName
//   location: sourceRGconfig.location
//   vnetName: sourceVnetconfig.vnetName
//   subnetName: sourceVnetconfig.subnets[0].name
//   properties: {
//     hardwareProfile: {
//       vmSize: 'Standard_DS1_v2'
//     }
//     osProfile: {
//       computerName: myVmName
//       adminUsername: 'azureuser'
//       adminPassword: 'Password123!'
//     }
//     storageProfile: {
//       imageReference: {
//         publisher: 'MicrosoftWindowsServer'
//         offer: 'WindowsServer'
//         sku: '2019-Datacenter'
//         version: 'latest'
//       }
//       osDisk: {
//         createOption: 'FromImage'
//       }
//     }
//   }
// }
