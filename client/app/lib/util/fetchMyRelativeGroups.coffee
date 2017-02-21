_ = require 'lodash'
kd = require 'kd'
whoami = require 'app/util/whoami'

###
  Fetches all groups that are you are owner of.
  Results:
    - doesn't include currentGroup
    - sorted by slug
###

module.exports = (callback) ->

  { groupsController } = kd.singletons
  currentGroup = groupsController.getCurrentGroup().slug
  whoami().fetchRelativeGroups { roles: ['owner'] }, (err, groups) ->

    return callback err  if err

    callback null, groups
