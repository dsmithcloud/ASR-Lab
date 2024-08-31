targetScope = 'subscription'

param sourceRGconfig object = {
  name: 'rg-myasrlab-source'
  location: 'uksouth'
}
param targetRGconfig object = {
  name: 'rg-myasrlab-target'
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
    {
      name: 'testfailover'
      properties: {
        addressPrefix: '10.1.1.0/24'
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

module publicIp1 './pip.bicep' = {
  name: '${sourceRGconfig.location}-pip'
  scope: sourceRG
  params: {
    vmName: sourceVmConfig.vmName
    location: sourceRGconfig.location
  }
}

module publicIp2 './pip.bicep' = {
  name: '${targetRGconfig.location}-pip'
  scope: targetRG
  params: {
    vmName: sourceVmConfig.vmName
    location: targetRGconfig.location
  }
}

module nsg1 './nsg.bicep' = {
  name: '${sourceVmConfig.vmName}-${sourceRGconfig.location}-nsg'
  scope: sourceRG
  params: {
    vmName: sourceVmConfig.vmName
    location: sourceRGconfig.location
    myIp: myhomeip
  }
}

module nsg2 './nsg.bicep' = {
  name: '${sourceVmConfig.vmName}-${targetRGconfig.location}-nsg'
  scope: targetRG
  params: {
    vmName: sourceVmConfig.vmName
    location: targetRGconfig.location
    myIp: myhomeip
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
    publicIp: publicIp1.outputs.pipId
    nsgId: nsg1.outputs.nsgId
  }
}

// Define the Traffic Manager profile
module trafficManager './trafficmanager.bicep' = {
  scope: sourceRG
  name: 'myTrafficManagerProfile'
  params: {
    profileName: '${sourceVmConfig.vmName}-trafficmanager'
    endpoint1Target: publicIp1.outputs.pipFqdn
    endpoint2Target: publicIp2.outputs.pipFqdn
  }
}

module automationacct './automation.bicep' = {
  name: 'asr-automationaccount'
  scope: targetRG
  params: {
    vaultName: '${asrvault.outputs.vaultName}-asr-automationaccount'
    location: targetRGconfig.location
  }
}

module storageacct './storage.bicep' = {
  name: 'smithasr' //value can be 11 characters long max
  scope: sourceRG
  params: {
    name: 'smithasr'
    location: sourceRGconfig.location
    sku: {
      name: 'Standard_LRS'
    }
  }
}
