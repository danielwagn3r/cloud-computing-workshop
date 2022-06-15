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

var dataFactoryName = 'adf-${uniqueString(baseName)}${toLower(environment)}'

resource dataFactoryName_resource 'Microsoft.DataFactory/factories@2018-06-01' =  {
  name: dataFactoryName
  location: location
  tags: resourceTags
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}
