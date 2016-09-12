kd = require 'kd'

module.exports = isStackTemplateSharedWithTeam = (baseStackId) ->

  { groupsController } = kd.singletons
  { stackTemplates } = groupsController.getCurrentGroup()

  return baseStackId in stackTemplates
