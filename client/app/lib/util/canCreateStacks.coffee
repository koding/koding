kd = require 'kd'
getGroup = require 'app/util/getGroup'
isAdmin = require 'app/util/isAdmin'

module.exports = canCreateStacks = ->
  isAdmin() or !!getGroup().customize?.membersCanCreateStacks
