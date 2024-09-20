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
  }
}

var subnet0name = vnetConfig.subnets[0].name
resource subnet0 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  name: subnet0name
  parent: virtualNetwork
  dependsOn: [nsg0]
  properties: {
    addressPrefix: vnetConfig.subnets[0].addressPrefix
    networkSecurityGroup: {
      id: nsg0.outputs.nsgId
    }
  }
}
var subnet1name = vnetConfig.subnets[1].name
resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  name: subnet1name
  parent: virtualNetwork
  dependsOn: [nsg1]
  properties: {
    addressPrefix: vnetConfig.subnets[1].addressPrefix
    networkSecurityGroup: {
      id: nsg1.outputs.nsgId
    }
  }
}

@description('Network Security Group for the subnets')
module nsg0 './nsg.bicep' = {
  name: '${Name}-${subnet0name}-nsg'
  scope: resourceGroup()
  dependsOn: [
    virtualNetwork
  ]
  params: {
    namePrefix: '${Name}-${vnetConfig.subnets[0].name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    securityRules: defaultNSGRules
  }
}
var nsg1Rules = (subnet1name == 'AzureBastionSubnet') ? bastionNSGRules : defaultNSGRules
module nsg1 './nsg.bicep' = {
  name: '${Name}-${subnet1name}-nsg'
  scope: resourceGroup()
  params: {
    namePrefix: '${Name}-${vnetConfig.subnets[1].name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    securityRules: nsg1Rules
  }
}

// Define the Diagnostic Settings for the VNet
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
output vnetId string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
output name string = virtualNetwork.name
