// this file can only be deployed at a subscription scope
targetScope = 'subscription'

@description('Base name of the project. All resource names will be derived from that.')
param baseName string = 'dataeng'

@description('Enable authorizations for devlopers')
param development bool = false

@description('Environment for the created resources.')
@allowed([
  'Dev'
  'Test'
  'Prod'
])
param environment string = 'Prod'

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Tags for the created resources')
param resourceTags object = {
  WorkloadName: 'Data Engineering'
  Dept: 'CUAS'
  Env: environment
  DataClassification: 'Confidential'
  Criticality: 'Mission-critical'
}

@description('Name of the Resource Group to create')
param rgName string = 'rg-${toLower(baseName)}-${toLower(environment)}'

@description('Location for the Resource Group')
param rgLocation string = 'westeurope'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: rgLocation
  tags: resourceTags
}

output resourceID string = rg.id

output adminUsername string = vmModule.outputs.adminUsername
output hostname string = vmModule.outputs.hostname
output sshCommand string = vmModule.outputs.sshCommand

module vmModule '01-vm/deploy.bicep' = {
  name: 'virtual-machine'
  scope: rg
  params: {
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    authenticationType: authenticationType
    baseName: baseName
    environment: environment
    location: rgLocation
    resourceTags: resourceTags
  }
}

module serviceBusModule '02-service-bus/deploy.bicep' = {
  name: 'service-bus'
  scope: rg
  params: {
    baseName: baseName
    development: development
    environment: environment
    location: rgLocation
    resourceTags: resourceTags
  }
}

module storageAccountModule '03-storage-account/deploy.bicep' = {
  name: 'storage-account'
  scope: rg
  params: {
    baseName: baseName
    development: development
    location: rgLocation
    environment: environment
    resourceTags: resourceTags
  }
}

module dataFactoryModule '04-adf/deploy.bicep' = {
  name: 'data-factory'
  scope: rg
  params: {
    baseName: baseName
    development: development
    location: rgLocation
    environment: environment
    resourceTags: resourceTags
  }
}

module deleteLockRG 'lock.bicep' = {
  name: 'rg-delete-lock'
  scope: rg
  params: {
    level: 'CanNotDelete'
  }
}

module readOnlyLockRG 'lock.bicep' = if (development == false) {
  name: 'rg-readonly-lock'
  scope: rg
  params: {
    level: 'ReadOnly'
  }
}
