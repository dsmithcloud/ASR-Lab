// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Bicep template to create the resources for a demo of Azure Site Recovery (ASR) for VMs.
DESCRIPTION: This Bicep file is used to deploy a VM in a source region and configure ASR to replicate the VM to a target region.
AUTHOR/S: David Smith (CSA FSI)
*/

// Scope
targetScope = 'subscription'

// Parameters & variables (see deployparam.yaml file)
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
param vmConfigs array

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
    parRemoteNetworkId: targetVnet.outputs.id
    parUseRemoteGateways: false
    parAllowGatewayTransit: false
  }
}
module peerTargetToSource './MODULES/vnetpeer.bicep' = {
  name: 'peer-${targetVnet.name}-${sourceVnet.name}'
  scope: targetRG
  params: {
    parHomeNetworkName: targetVnet.outputs.name
    parRemoteNetworkId: sourceVnet.outputs.id
    parUseRemoteGateways: false
    parAllowGatewayTransit: false
  }
}

@description('Azure Bastion in the source region')
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
module kv './MODULES/keyvault.bicep' = {
  name: 'keyvault'
  scope: sourceRG
  params: {
    namePrefix: parDeploymentPrefix
    secretName: 'vmAdminPassword'
    vmAdminPassword: vmAdminPassword
    userPrincipalId: 'f07e7ee2-d553-4c07-ba96-369a7500f87b'
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    logAnalytics
  ]
}

@description('Load Balancer')
module lb './Modules/loadbalancer.bicep' = {
  name: 'loadbalancer'
  scope: sourceRG
  params: {
    namePrefix: parDeploymentPrefix
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    logAnalytics
    sourceVnet
  ]
}

@description('VM deployments')
var adminUsername = 'azadmin'
var vmSubnetId = sourceVnet.outputs.subnets[0].id
module vmDeployments './MODULES/vm.bicep' = [
  for vmConfig in vmConfigs: if (vmConfig.deploy) {
    name: 'vm-${vmConfig.purpose}'
    scope: sourceRG
    dependsOn: [
      sourceVnet
    ]
    params: {
      namePrefix: parDeploymentPrefix
      nameSuffix: vmConfig.nameSuffix
      purpose: vmConfig.purpose
      vmSize: vmConfig.vmSize
      osDiskSize: vmConfig.osDiskSize
      dataDiskSize: vmConfig.dataDiskSize
      osType: vmConfig.osType
      adminUsername: adminUsername
      adminPassword: vmAdminPassword
      imagePublisher: vmConfig.imagePublisher
      imageOffer: vmConfig.imageOffer
      imageSku: vmConfig.imageSku
      imageVersion: vmConfig.imageVersion
      publicIp: vmConfig.publicIp
      subnetId: vmSubnetId
      logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    }
  }
]

// @description('Traffic Manager profile for the web site on the source VM')
// module trafficManager './MODULES/trafficmanager.bicep' = {
//   scope: sourceRG
//   name: 'myTrafficManagerProfile'
//   params: {
//     profileName: vmConfig.vmName
//     endpoint1Target: publicIp1.outputs.pipFqdn
//     endpoint2Target: publicIp2.outputs.pipFqdn
//     logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
//   }
// }

// // Output
// output fqdn string = trafficManager.outputs.trafficManagerfqdn
// output vmNames string = vmNames
