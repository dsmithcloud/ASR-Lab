// Parameters & variables
@description('ASR Vault Name, Location and SKU')
param vaultName string
param location string
param sku object
param logAnalyticsWorkspaceId string

// Resources
@description('ASR Vault configuration in the target region')
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

resource diagsettingsbackup 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${recoveryServicesVault.name}-backupdiag'
  scope: recoveryServicesVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AzureBackupReport'
        enabled: true
      }
      {
        category: 'CoreAzureBackup'
        enabled: true
      }
      {
        category: 'AddonAzureBackupJobs'
        enabled: true
      }
      {
        category: 'AddonAzureBackupAlerts'
        enabled: true
      }
      {
        category: 'AddonAzureBackupPolicy'
        enabled: true
      }
      {
        category: 'AddonAzureBackupStorage'
        enabled: true
      }
      {
        category: 'AddonAzureBackupProtectedInstance'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Health'
        enabled: true
      }
    ]
    logAnalyticsDestinationType: null
  }
}

resource diagsettingssiterecovery 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${recoveryServicesVault.name}-siterecoverydiag'
  scope: recoveryServicesVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AzureSiteRecoveryJobs'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryEvents'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryReplicatedItems'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryReplicationStats'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryRecoveryPoints'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryReplicationDataUploadRate'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryProtectedDiskDataChurn'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Health'
        enabled: false
      }
    ]
    logAnalyticsDestinationType: null
  }
}

// Output
@description('Output the vault name')
output vaultName string = recoveryServicesVault.name
