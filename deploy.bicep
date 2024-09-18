// Description: This Bicep file is used to deploy a VM in a source region and configure ASR to replicate the VM to a target region.
targetScope = 'subscription'

// Command Line Parameters & variables
param parDeploymentPrefix string = 'asrdemo'
param sourceLocation string = 'uksouth'
param targetLocation string = 'ukwest'

// Run-time Parameters & variables
@description('Resource Group configurations for source and target')
var sourceRGconfig = {
  name: 'rg-${parDeploymentPrefix}-source'
  location: sourceLocation
}
var targetRGconfig = {
  name: 'rg-${parDeploymentPrefix}-target'
  location: targetLocation
}

@description('ASR Vault configuration in the target region')
var rsvvaultconfig = {
  vaultName: '${parDeploymentPrefix}-vault'
  location: targetRGconfig.location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}

@description('VNet configurations for source')
var vnet1config = {
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
    {
      name: 'AzureBastionSubnet'
      properties: {
        addressPrefix: '10.0.2.0/24'
      }
    }
  ]
}

@description('VNet configurations for target')
var vnet2config = {
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

@description('Source VM configuration')
var myVmName = 'sourceVm'
var sourceVmConfig = {
  vmName: myVmName
  location: sourceRGconfig.location
  vnetName: vnet1config.vnetName
  subnetName: vnet1config.subnets[0].name
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: myVmName
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

// Resources
@description('Resource Groups for source and target')
resource sourceRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${sourceRGconfig.name}-${sourceRGconfig.location}'
  location: sourceRGconfig.location
}
resource targetRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${targetRGconfig.name}-${targetRGconfig.location}'
  location: targetRGconfig.location
}

@description('ASR Vault in the target region')
module asrvault './MODULES/asrvault.bicep' = {
  name: 'asrvault'
  scope: targetRG
  params: {
    vaultName: rsvvaultconfig.vaultName
    location: rsvvaultconfig.location
    sku: rsvvaultconfig.sku
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

@description('Log Analytics Account in Source Region')
module logAnalytics './MODULES/monitor.bicep' = {
  name: 'loganalytics'
  scope: sourceRG
  params: {
    name: 'loganalytics'
    location: sourceRGconfig.location
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

@description('VNet configurations for source and target')
module vnet1 './MODULES/vnet.bicep' = {
  name: vnet1config.vnetName
  scope: sourceRG
  params: {
    name: 'vnet1-${sourceRGconfig.location}'
    location: sourceRGconfig.location
    addressSpace: vnet1config.addressSpace
    subnets: vnet1config.subnets
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}
module vnet2 './MODULES/vnet.bicep' = {
  name: vnet2config.vnetName
  scope: targetRG
  params: {
    name: 'vnet2-${targetRGconfig.location}'
    location: targetRGconfig.location
    addressSpace: vnet2config.addressSpace
    subnets: vnet2config.subnets
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module peering1 './MODULES/vnetpeer.bicep' = {
  name: 'peering1'
  scope: sourceRG
  params: {
    parHomeNetworkName: vnet1.outputs.name
    parRemoteNetworkId: vnet2.outputs.vnetId
    parUseRemoteGateways: false
    parAllowGatewayTransit: false
  }
}

module peering2 './MODULES/vnetpeer.bicep' = {
  name: 'peering2'
  scope: targetRG
  params: {
    parHomeNetworkName: vnet2.outputs.name
    parRemoteNetworkId: vnet1.outputs.vnetId
    parUseRemoteGateways: false
    parAllowGatewayTransit: false
  }
}

@description('Public IP configurations for source and target')
module publicIp1 './MODULES/pip.bicep' = {
  name: '${sourceRGconfig.location}-pip'
  scope: sourceRG
  params: {
    namePrefix: sourceVmConfig.vmName
    location: sourceRGconfig.location
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    skuName: 'Basic'
  }
}
module publicIp2 './MODULES/pip.bicep' = {
  name: '${targetRGconfig.location}-pip'
  scope: targetRG
  params: {
    namePrefix: sourceVmConfig.vmName
    location: targetRGconfig.location
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    skuName: 'Basic'
  }
}
module bastionpublicIp './MODULES/pip.bicep' = {
  name: 'bastion-pip'
  scope: sourceRG
  params: {
    namePrefix: 'bastion'
    location: sourceRG.location
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    skuName: 'Standard'
  }
}

module bastion './MODULES/bastion.bicep' = {
  name: 'bastion'
  scope: sourceRG
  params: {
    bastionName: 'myBastion'
    location: sourceRGconfig.location
    bastionSubnetId: vnet1.outputs.subnets[1].id
    bastionPublicIpId: bastionpublicIp.outputs.pipId
  }
  dependsOn: [
    vnet1
    publicIp1
    nsg1
    peering1
    peering2
  ]
}

@description('Network Security Group for source and target')
module nsg1 './MODULES/nsg.bicep' = {
  name: '${sourceVmConfig.vmName}-${sourceRGconfig.location}-nsg'
  scope: sourceRG
  params: {
    vmName: sourceVmConfig.vmName
    location: sourceRGconfig.location
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}
module nsg2 './MODULES/nsg.bicep' = {
  name: '${sourceVmConfig.vmName}-${targetRGconfig.location}-nsg'
  scope: targetRG
  params: {
    vmName: sourceVmConfig.vmName
    location: targetRGconfig.location
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

@description('Source VM configuration')
module sourceVm './MODULES/vm.bicep' = {
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
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    vnet1
    publicIp1
    nsg1
    peering1
    peering2
  ]
}

@description('Traffic Manager profile for the web site on the source VM')
module trafficManager './MODULES/trafficmanager.bicep' = {
  scope: sourceRG
  name: 'myTrafficManagerProfile'
  params: {
    profileName: sourceVmConfig.vmName
    endpoint1Target: publicIp1.outputs.pipFqdn
    endpoint2Target: publicIp2.outputs.pipFqdn
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

@description('Automation Account for ASR')
module automationacct './MODULES/automation.bicep' = {
  name: 'asr-automationaccount'
  scope: targetRG
  params: {
    vaultName: '${asrvault.outputs.vaultName}-asr-automationaccount'
    location: targetRGconfig.location
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

@description('Storage account for ASR cache')
module storageacct './MODULES/storage.bicep' = {
  name: 'asr' //value can be 11 characters long max
  scope: sourceRG
  params: {
    name: 'asr'
    location: sourceRGconfig.location
    sku: {
      name: 'Standard_LRS'
    }
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

// Output
output fqdn string = trafficManager.outputs.trafficManagerfqdn
