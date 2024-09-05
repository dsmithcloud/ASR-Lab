param vaultName string
param location string
param sku object

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: vaultName
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: sku.name
    tier: sku.tier
  }
}

resource replicationPolicies 'Microsoft.RecoveryServices/vaults/replicationPolicies@2024-04-01' = {
  name: '24-hour-retention-policy'
  parent: recoveryServicesVault
  properties: {
    providerSpecificInput: {
      instanceType: 'A2A'
      multiVmSyncStatus: 'Disable'
    }
  }
}

output vaultName string = recoveryServicesVault.name
