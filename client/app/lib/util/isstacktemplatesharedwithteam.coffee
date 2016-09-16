kd = require 'kd'

module.exports = isStackTemplateSharedWithTeam = (baseStackId) ->

  { groupsController } = kd.singletons
  stackTemplates = groupsController.getCurrentGroup().stackTemplates ? []

  return baseStackId in stackTemplates
