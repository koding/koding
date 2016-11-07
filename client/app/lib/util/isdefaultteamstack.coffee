kd = require 'kd'

module.exports = isDefaultTeamStack = (baseStackId) ->

  { groupsController } = kd.singletons
  stackTemplates = groupsController.getCurrentGroup().sharedStackTemplates ? []

  return baseStackId in stackTemplates
