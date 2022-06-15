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

var serviceBusName = 'sb-${uniqueString(baseName)}-${toLower(environment)}'
var topicName = 'topic'
var archiveSubscriptionNameSuffix = 'archive'
var readerSubscriptionNameSuffix = 'reader'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
  }
  tags: resourceTags

  resource developerAuthororization 'AuthorizationRules@2021-06-01-preview' = if (development) {
    name: 'developer'
    properties: {
      rights: [
        'Manage'
        'Listen'
        'Send'
      ]
    }
  }

  resource archiveReaderAuthorization 'AuthorizationRules@2021-06-01-preview' = {
    name: 'archive-reader'
    properties: {
      rights: [
        'Listen'
      ]
    }
  }
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2021-06-01-preview' = {
  parent: serviceBusNamespace
  name: topicName
  properties: {
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    defaultMessageTimeToLive: 'P1D'
    enableBatchedOperations: true
    requiresDuplicateDetection: false
    supportOrdering: true
  }

  resource senderAuthorization 'AuthorizationRules@2021-06-01-preview' = {
    name: 'sender'
    properties: {
      rights: [
        'Send'
      ]
    }
  }

  resource readerAuthorization 'AuthorizationRules@2021-06-01-preview' = {
    name: 'reader'
    properties: {
      rights: [
        'Listen'
      ]
    }
  }

  resource archiveSubscription 'subscriptions@2021-06-01-preview' = {
    name: '${topicName}-${archiveSubscriptionNameSuffix}'
    properties: {
      autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
      deadLetteringOnFilterEvaluationExceptions: true
      deadLetteringOnMessageExpiration: true
      defaultMessageTimeToLive: 'P1D'
      lockDuration: 'PT30S'
      maxDeliveryCount: 10
      requiresSession: false
    }
  }

  resource typeOneSubscription 'subscriptions@2021-06-01-preview' = {
    name: '${topicName}-${readerSubscriptionNameSuffix}-one-1.0.0'
    properties: {
      autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
      defaultMessageTimeToLive: 'P1D'
      maxDeliveryCount: 10
      deadLetteringOnFilterEvaluationExceptions: true
      deadLetteringOnMessageExpiration: true
      requiresSession: false
    }
    resource typeOneSubscriptionMessageSchemaRule 'rules@2021-06-01-preview' = {
      name: 'messageschema'
      properties: {
        filterType: 'SqlFilter'
        sqlFilter: {
          sqlExpression: 'user.metadata_type = \'one\' AND user.metadata_version = \'1.0.0\''
        }
      }
    }
  }
  resource typeTwoSubscription 'subscriptions@2021-06-01-preview' = {
    name: '${topicName}-${readerSubscriptionNameSuffix}-two-1.0.0'
    properties: {
      autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
      deadLetteringOnFilterEvaluationExceptions: true
      deadLetteringOnMessageExpiration: true
      defaultMessageTimeToLive: 'P1D'
      lockDuration: 'PT30S'
      maxDeliveryCount: 10
      requiresSession: false
    }
    resource typeTwoSubscriptionMessageSchemaRule 'rules@2021-06-01-preview' = {
      name: 'messageschema'
      properties: {
        filterType: 'SqlFilter'
        sqlFilter: {
          sqlExpression: 'user.metadata_type = \'two\' AND user.metadata_version = \'1.0.0\''
        }
      }
    }
  }
}
