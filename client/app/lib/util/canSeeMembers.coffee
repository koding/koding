getGroup = require 'app/util/getGroup'

module.exports = canSeeMembers = -> not getGroup().customize?.hideTeamMembers
