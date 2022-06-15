// this file can only be deployed at a subscription scope
targetScope = 'resourceGroup'

@description('Base name of the project. All resource names will be derived from that.')
param baseName string = 'dataeng'

@description('Location for the created resources.')
param location string = resourceGroup().location

@description('Enable authorizations for development')
param development bool = false

@description('Environment for the created resources.')
@allowed([
  'Dev'
  'Test'
  'Prod'
])
param environment string = 'Prod'

@description('Tags for the created resources.')
param resourceTags object = {
  WorkloadName: 'Data Engineering'
  Dept: 'CUAS'
  Env: environment
  DataClassification: 'Confidential'
  Criticality: 'Mission-critical'
}

var storageAccountName = 'st${uniqueString(baseName)}${toLower(environment)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  tags: resourceTags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
    }
  }

  resource archiveContainer 'containers@2021-06-01' = {
    name: 'lego'
    properties: {
      publicAccess: 'None'
    }
  }
}

resource files 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}
