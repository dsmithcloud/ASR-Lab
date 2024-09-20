// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Bicep template to create the resources for a demo of Azure Site Recovery (ASR) for VMs.
DESCRIPTION: This Bicep file is used to deploy a VM in a source region and configure ASR to replicate the VM to a target region.
AUTHOR/S: David Smith (CSA FSI)
*/

// Scope
targetScope = 'subscription'

// Parameters & variables (see deploy.bicepparam file)
@description('Deployment Prefix')
param parDeploymentPrefix string
@description('Source VM Region')
param sourceLocation string
@description('Target VM Region')
param targetLocation string
@secure()
param vmAdminPassword string
@description('VNet configurations for source')
param sourceVnetConfig object
@description('VNet configurations for target')
param targetVnetConfig object
// param sourceVmConfig object

// Resources
@description('Resource Groups for source and target')
resource sourceRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${parDeploymentPrefix}-source-${sourceLocation}-rg'
  location: sourceLocation
}
@description('Resource Groups for source and target')
resource targetRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${parDeploymentPrefix}-target-${targetLocation}-rg'
  location: targetLocation
}

@description('Log Analytics Account in Source Region')
module logAnalytics './MODULES/monitor.bicep' = {
  name: 'loganalytics'
  scope: sourceRG
  params: {
    namePrefix: parDeploymentPrefix
  }
}

@description('ASR Vault in the target region')
module asrvault './MODULES/asrvault.bicep' = {
  name: 'asrvault'
  scope: targetRG
  params: {
    namePrefix: parDeploymentPrefix
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    logAnalytics
  ]
}

@description('Automation Account for ASR')
module automationacct './MODULES/automation.bicep' = {
  name: 'asr-automationaccount'
  scope: targetRG
  params: {
    namePrefix: parDeploymentPrefix
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

@description('Storage account for ASR cache')
module storageacct './MODULES/storage.bicep' = {
  name: 'storageacct-${sourceLocation}'
  scope: sourceRG
  params: {
    namePrefix: parDeploymentPrefix
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

@description('VNet configurations for source and target')
module sourceVnet './MODULES/vnet.bicep' = {
  name: 'vnet-${sourceLocation}'
  scope: sourceRG
  params: {
    namePrefix: parDeploymentPrefix
    vnetConfig: sourceVnetConfig
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    logAnalytics
  ]
}
module targetVnet './MODULES/vnet.bicep' = {
  name: 'vnet-${targetLocation}'
  scope: targetRG
  params: {
    namePrefix: parDeploymentPrefix
    vnetConfig: targetVnetConfig
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    logAnalytics
  ]
}

module peerSourceToTarget './MODULES/vnetpeer.bicep' = {
  name: 'peer-${sourceVnet.name}-${targetVnet.name}'
  scope: sourceRG
  params: {
    parHomeNetworkName: sourceVnet.outputs.name
    parRemoteNetworkId: targetVnet.outputs.vnetId
    parUseRemoteGateways: false
    parAllowGatewayTransit: false
  }
  dependsOn: [
    sourceVnet
    targetVnet
  ]
}
module peerTargetToSource './MODULES/vnetpeer.bicep' = {
  name: 'peer-${targetVnet.name}-${sourceVnet.name}'
  scope: targetRG
  params: {
    parHomeNetworkName: targetVnet.outputs.name
    parRemoteNetworkId: sourceVnet.outputs.vnetId
    parUseRemoteGateways: false
    parAllowGatewayTransit: false
  }
  dependsOn: [
    sourceVnet
    targetVnet
  ]
}

module bastion './MODULES/bastion.bicep' = {
  name: 'bastion'
  scope: sourceRG
  params: {
    namePrefix: parDeploymentPrefix
    bastionSubnetId: resourceId(
      subscription().subscriptionId,
      sourceRG.name,
      'Microsoft.Network/virtualNetworks/subnets',
      sourceVnet.outputs.name,
      'AzureBastionSubnet'
    )
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    logAnalytics
    sourceVnet
    peerSourceToTarget
    peerTargetToSource
  ]
}

@description('Key Vault in the source region')
module keyvault './MODULES/keyvault.bicep' = {
  name: 'keyvault'
  scope: sourceRG
  params: {
    namePrefix: parDeploymentPrefix
    secretName: 'vmAdminPassword'
    vmAdminPassword: vmAdminPassword
    // userPrincipalId: '00000000-0000-0000-0000-000000000000'
  }
  dependsOn: [
    logAnalytics
  ]
}

// @description('Public IP configurations for source and target')
// module publicIp1 './MODULES/pip.bicep' = {
//   name: '${sourceRGconfig.location}-pip'
//   scope: sourceRG
//   params: {
//     namePrefix: sourceVmConfig.vmName
//     location: sourceRGconfig.location
//     logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
//     skuName: 'Basic'
//   }
// }
// module publicIp2 './MODULES/pip.bicep' = {
//   name: '${targetRGconfig.location}-pip'
//   scope: targetRG
//   params: {
//     namePrefix: sourceVmConfig.vmName
//     location: targetRGconfig.location
//     logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
//     skuName: 'Basic'
//   }
// }

// @description('Source VM configuration')
// module sourceVm './MODULES/vm.bicep' = {
//   name: sourceVmConfig.vmName
//   scope: sourceRG
//   params: {
//     vmName: sourceVmConfig.vmName
//     location: sourceVmConfig.location
//     hardwareProfile: sourceVmConfig.properties.hardwareProfile
//     osProfile: sourceVmConfig.properties.osProfile
//     storageProfile: sourceVmConfig.properties.storageProfile
//     subnetId: sourceVnet.outputs.subnets[0].id
//     publicIp: publicIp1.outputs.pipId
//     nsgId: nsg1.outputs.nsgId
//     logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
//   }
//   dependsOn: [
//     sourceVnet
//     publicIp1
//     nsg1
//     peerSourceToTarget
//     peerTargetToSource
//   ]
// }

// @description('Traffic Manager profile for the web site on the source VM')
// module trafficManager './MODULES/trafficmanager.bicep' = {
//   scope: sourceRG
//   name: 'myTrafficManagerProfile'
//   params: {
//     profileName: sourceVmConfig.vmName
//     endpoint1Target: publicIp1.outputs.pipFqdn
//     endpoint2Target: publicIp2.outputs.pipFqdn
//     logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
//   }
// }

// // Output
// output fqdn string = trafficManager.outputs.trafficManagerfqdn
