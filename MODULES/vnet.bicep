// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to create a Virtual Network
DESCRIPTION: This module will create a deployment which will create a Virtual Network
AUTHOR/S: David Smith (CSA FSI)
*/

param namePrefix string
var location = resourceGroup().location
var nameSuffix = 'vnet'
var Name = '${namePrefix}-${location}-${nameSuffix}'
param vnetConfig object
param logAnalyticsWorkspaceId string
@description('Network Security Group for the subnets')
var defaultNSGRules = [
  {
    name: 'IngressfromAzureBastion'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRanges: [
        '3389'
        '22'
      ]
      sourceAddressPrefix: vnetConfig.subnets[1].addressPrefix
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'Allow-HTTP-From-Specific-IP'
    properties: {
      priority: 110
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '80'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'Allow-Internet-Outbound'
    properties: {
      priority: 120
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
    }
  }
]
@description('Network Security Group for the Azure Bastion subnet')
var bastionNSGRules = [
  {
    name: 'AllowHttpsInbound'
    properties: {
      priority: 120
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'AllowGatewayManagerInbound'
    properties: {
      priority: 130
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'GatewayManager'
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'AllowAzureLoadBalancerInbound'
    properties: {
      priority: 140
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'AllowBastionHostCommunication'
    properties: {
      priority: 150
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  {
    name: 'AllowSshRdpOutbound'
    properties: {
      priority: 100
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRanges: [
        '22'
        '3389'
      ]
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  {
    name: 'AllowAzureCloudOutbound'
    properties: {
      priority: 110
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'AzureCloud'
    }
  }
  {
    name: 'AllowBastionCommunication'
    properties: {
      priority: 120
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  {
    name: 'AllowHttpOutbound'
    properties: {
      priority: 130
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '80'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
    }
  }
]

// Resources
@description('Virtual Network')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: Name
  location: location
  properties: {
    addressSpace: vnetConfig.addressSpace
    subnets: [
      for subnet in vnetConfig.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
        }
      }
    ]
  }
}

@description('Network Security Group for the subnets')
module nsg './nsg.bicep' = [
  for subnet in vnetConfig.subnets: {
    name: '${Name}-${subnet.name}-nsg'
    scope: resourceGroup()
    dependsOn: [
      virtualNetwork
    ]
    params: {
      namePrefix: '${Name}-${vnetConfig.subnets[0].name}'
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
      securityRules: (subnet.name == 'AzureBastionSubnet') ? bastionNSGRules : defaultNSGRules
    }
  }
]

@description('Define the Diagnostic Settings for the VNet')
resource vnetDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${virtualNetwork.name}-diag'
  scope: virtualNetwork
  properties: {
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

// Output
@description('Output the virtual network ID & subnets')
output vnets object = virtualNetwork
output name string = virtualNetwork.name
output id string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
