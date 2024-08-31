@description('Name of the Recovery Services Vault')
param vaultName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Storage redundancy type')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
])
param storageRedundancy string = 'GeoRedundant'

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-02-01' = {
  name: vaultName
  location: location
  properties: {}
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}

resource vaultStorageConfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2022-02-01' = {
  parent: recoveryServicesVault
  name: 'vaultstorageconfig'
  properties: {
    storageModelType: storageRedundancy
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'myVNet'
  location: location
  properties: {
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
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'myLogAnalyticsWorkspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'myVM'
  location: location
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
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'myNic')
        }
      ]
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'myNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVNet', 'default')
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}
```

This Bicep code sets up a Recovery Services Vault, a virtual network, a Log Analytics workspace, and a virtual machine, which are key components for an Azure Site Recovery lab. You can customize the parameters and resource properties as needed to match the specific requirements of your lab setup.

If you need further customization or have any questions, feel free to ask!

Source: Conversation with Copilot, 8/29/2024
(1) Quickstart to create an Azure Recovery Services vault using Bicep .... https:
//learn.microsoft.com/en-us/azure/site-recovery/quickstart-create-vault-bicep.
(2) nicolalgallacher/azure-site-recovery-demo-bicep- - GitHub. https:
//github.com/nicolalgallacher/azure-site-recovery-demo-bicep-.
(3) Introduction to using Azure Verified Modules for Bicep - Code Samples .... https:
//learn.microsoft.com/en-us/samples/azure-samples/avm-bicep-labs/avm-bicep-labs/.
(4) Create a lab using Bicep - Azure Lab Services | Microsoft Learn. https:
//learn.microsoft.com/en-us/azure/lab-services/how-to-create-lab-bicep.
