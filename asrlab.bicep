targetScope = 'subscription'

param sourceRGconfig object = {
  name: 'rg-asrlab-source'
  location: 'uksouth'
}
param targetRGconfig object = {
  name: 'rg-asrlab-target'
  location: 'ukwest'
}

param rsvvaultconfig object = {
  vaultName: 'asrvault'
  location: targetRGconfig.location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}

param vnet1config object = {
  vnetName: 'vnet1'
  location: sourceRGconfig.location
  addressSpace: {
    addressPrefixes: [
      '10.0.0.0/16'
    ]
  }
  subnets: [
    {
      name: 'default'
      properties: {
        addressPrefix: '10.0.0.0/24'
      }
    }
  ]
}

param vnet2config object = {
  vnetName: 'vnet2'
  location: sourceRGconfig.location
  addressSpace: {
    addressPrefixes: [
      '10.1.0.0/16'
    ]
  }
  subnets: [
    {
      name: 'default'
      properties: {
        addressPrefix: '10.1.0.0/24'
      }
    }
  ]
}

param sourceVmConfig object = {
  vmName: 'sourceVm'
  location: sourceRGconfig.location
  vnetName: vnet1config.vnetName
  subnetName: vnet1config.subnets[0].name
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: 'myVM'
      adminUsername: 'azureuser'
      adminPassword: 'Password123!'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
}

param myhomeip string = '20.97.9.18'

resource sourceRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${sourceRGconfig.name}-${sourceRGconfig.location}'
  location: sourceRGconfig.location
}

resource targetRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${targetRGconfig.name}-${targetRGconfig.location}'
  location: targetRGconfig.location
}

module asrvault './asrvault.bicep' = {
  name: 'asrvault'
  scope: targetRG
  params: {
    vaultName: rsvvaultconfig.vaultName
    location: rsvvaultconfig.location
    sku: rsvvaultconfig.sku
  }
}

module vnet1 './vnet.bicep' = {
  name: vnet1config.vnetName
  scope: sourceRG
  params: {
    name: 'vnet1-${sourceRGconfig.location}'
    location: sourceRGconfig.location
    addressSpace: vnet1config.addressSpace
    subnets: vnet1config.subnets
  }
}

module vnet2 './vnet.bicep' = {
  name: vnet2config.vnetName
  scope: sourceRG
  params: {
    name: 'vnet2-${targetRGconfig.location}'
    location: targetRGconfig.location
    addressSpace: vnet2config.addressSpace
    subnets: vnet2config.subnets
  }
}

module sourceVm './vm.bicep' = {
  name: sourceVmConfig.vmName
  scope: sourceRG
  params: {
    vmName: sourceVmConfig.vmName
    location: sourceVmConfig.location
    hardwareProfile: sourceVmConfig.properties.hardwareProfile
    osProfile: sourceVmConfig.properties.osProfile
    storageProfile: sourceVmConfig.properties.storageProfile
    subnetId: vnet1.outputs.subnets[0].id
    internetIP: myhomeip
  }
}

// // Define the Traffic Manager profile
// module trafficManager './trafficmanager.bicep' = {
//   scope: sourceRG
//   name: 'myTrafficManagerProfile'
//   params: {}
// }
