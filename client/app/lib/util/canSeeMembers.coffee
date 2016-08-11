kd = require 'kd'

module.exports = canSeeMembers = ->
  !kd.singletons.groupsController.getCurrentGroup().customize?.hideTeamMembers
