_ = require 'lodash'
kd = require 'kd'
whoami = require 'app/util/whoami'

###
  Fetches all groups that are associated with you
  Removes current group
  Sort them by group name
###

module.exports = (callback) ->

  { groupsController } = kd.singletons
  currentGroup = groupsController.getCurrentGroup().slug
  whoami().fetchRelativeGroups { currentGroup, roles: ['owner'] }, (err, groups) ->

    return callback err  if err

    callback null, groups
