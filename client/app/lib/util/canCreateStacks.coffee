kd = require 'kd'
getGroup = require 'app/util/getGroup'

module.exports = canCreateStacks = ->
  isAdmin() or !!getGroup().customize?.membersCanCreateStacks
