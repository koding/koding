kd = require 'kd'
isAdmin = require 'app/util/isAdmin'

module.exports = canCreateStacks = ->
  isAdmin() or !!kd.singletons.groupsController.getCurrentGroup().customize?.membersCanCreateStacks
