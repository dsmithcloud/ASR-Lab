param vaultName string
param location string
param sku object

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-02-01' = {
  name: vaultName
  location: location
  properties: {}
  sku: {
    name: sku.name
    tier: sku.tier
  }
}

output vaultName string = recoveryServicesVault.name
