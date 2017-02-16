kd = require 'kd'
_ = require 'lodash'
async = require 'async'
whoami = require 'app/util/whoami'
KodingListController = require 'app/kodinglist/kodinglistcontroller'
ChangeTeamListItem = require './itemview'
showError = require 'app/util/showError'

module.exports = class ChangeTeamController extends KodingListController

  constructor: (options = {}, data) ->

    options.itemClass      = ChangeTeamListItem
    options.loadWithScroll = no
    options.fetcherMethod  = (query, options, callback) ->
      whoami().fetchRelativeGroups (err, groups) ->
        return  if showError err

        { groupsController } = kd.singletons
        currentGroup = _.find groups, (group) ->
          group.slug is groupsController.getCurrentGroup().slug

        rejectedSlugs = [ 'koding', currentGroup.slug ]
        groups = _.reject groups, (group) -> group.slug in rejectedSlugs
        groups = _.sortBy groups, 'slug'

        groups.unshift currentGroup

        callback null, groups

    options.noItemFoundWidget = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'no-item-found'
      partial  : 'No item found!'

    super options, data
