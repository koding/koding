_  = require 'lodash'
kd = require 'kd'

module.exports = collectCredentials = ->

  providers             = []
  variables             = {}
  { computeController } = kd.singletons
  { stacks }            = computeController

  for stack in stacks
    providers = providers.concat stack.config?.requiredProviders
    variables = _.assign variables, stack.config?.requiredData

  return { providers, variables }
