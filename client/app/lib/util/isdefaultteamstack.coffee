kd = require 'kd'

module.exports = isDefaultTeamStack = (baseStackId) ->

  { groupsController } = kd.singletons
  stackTemplates = groupsController.getCurrentGroup().stackTemplates ? []

  return baseStackId in stackTemplates
