_ = require 'lodash'
kd = require 'kd'
whoami = require 'app/util/whoami'

###
  Fetches all groups that are associated with you
  Removes current group
  Sort them by group name
###

module.exports = (callback) ->

  whoami().fetchRelativeGroups (err, groups) ->

    return callback err  if err

    { groupsController } = kd.singletons
    currentGroup = _.find groups, (group) ->
      group.slug is groupsController.getCurrentGroup().slug

    rejectedSlugs = [ 'koding', currentGroup.slug ]
    groups = _.reject groups, (group) ->
      group.slug in rejectedSlugs

    groups = _.sortBy groups, 'slug'

    callback null, groups
