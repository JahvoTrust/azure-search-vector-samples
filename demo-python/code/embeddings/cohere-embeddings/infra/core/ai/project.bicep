@description('The AI Studio Hub Resource name')
param name string
@description('The display name of the AI Studio Hub Resource')
param displayName string = name
@description('The name of the AI Studio Hub Resource where this project should be created')
param hubName string
@description('The name of the key vault resource to grant access to the project')
param keyVaultName string

@description('The SKU name to use for the AI Studio Hub Resource')
param skuName string = 'Basic'
@description('The SKU tier to use for the AI Studio Hub Resource')
@allowed(['Basic', 'Free', 'Premium', 'Standard'])
param skuTier string = 'Basic'
@description('The public network access setting to use for the AI Studio Hub Resource')
@allowed(['Enabled','Disabled'])
param publicNetworkAccess string = 'Enabled'

param location string = resourceGroup().location
param tags object = {}

resource project 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: displayName
    hbiWorkspace: false
    v1LegacyMode: false
    publicNetworkAccess: publicNetworkAccess
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
    // most properties are not allowed for a project workspace: "Project workspace shouldn't define ..."
    hubResourceId: hub.id
  }
}

module keyVaultAccess '../security/keyvault-access.bicep' = {
  name: 'keyvault-access'
  params: {
    keyVaultName: keyVaultName
    principalId: project.identity.principalId
  }
}

resource hub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing = {
  name: hubName
}

output id string = project.id
output name string = project.name
output principalId string = project.identity.principalId
