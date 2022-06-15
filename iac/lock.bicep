@description('Environment for the created resources.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'NotSpecified'
])
param level string = 'CanNotDelete'

param name string = 'lock-${toLower(level)}'

param notes string = 'Resource should not be deleted.'

resource lock 'Microsoft.Authorization/locks@2017-04-01' = {
  name: name
  scope: resourceGroup()
  properties: {
    level: level
    notes: notes
  }
}
