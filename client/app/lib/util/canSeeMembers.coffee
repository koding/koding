getGroup = require 'app/util/getGroup'

module.exports = canSeeMembers = ->
  !getGroup().customize?.hideTeamMembers
