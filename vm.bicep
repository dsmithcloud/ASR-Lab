// Parameters & variables
@description('VM Name, Location, Hardware Profile, OS Profile, Storage Profile, Subnet ID, Public IP ID, NSG ID')
param vmName string
param location string
param hardwareProfile object
param osProfile object
param storageProfile object
param subnetId string
param publicIp string
param nsgId string
param logAnalyticsWorkspaceId string
param storageAccountName string
var diagnosticConfig = {
  xmlCfg: json(loadTextContent('./wadcfg.json'))
  storageAccount: storageAccountName
  protectedSettings: {
    storageAccountName: storageAccountName
    storageAccountKey: logAnalyticsWorkspaceId
  }
}

// Resources
@description('Network interface')
resource networkInterface 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

@description('Virtual machine')
resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: hardwareProfile
    osProfile: osProfile
    storageProfile: storageProfile
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

@description('Custom script extension to deploy IIS')
resource iisExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: virtualMachine
  name: 'iisExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/dsmithcloud/ASR-Lab/main/DeployIIS.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File DeployIIS.ps1'
    }
  }
}

resource diagExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: 'IaaSDiagnostics'
  parent: virtualMachine
  properties: {
    publisher: 'Microsoft.Azure.Diagnostics'
    type: 'IaaSDiagnostics'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    settings: diagnosticConfig
  }
}

// Define the Diagnostic Settings for the NIC
resource nicDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'nicDiagSettings'
  scope: networkInterface
  properties: {
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

// Define the Diagnostic Settings for the VM
resource vmDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vmDiagSettings'
  scope: virtualMachine
  properties: {
    logs: [
      {
        category: 'GuestOS'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'BootDiagnostics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

// Output
@description('Output the VM ID and NIC ID')
output vmId string = virtualMachine.id
output vmNicId string = networkInterface.id
