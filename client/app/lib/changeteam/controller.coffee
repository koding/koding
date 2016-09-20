kd = require 'kd'
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
        groups = groups.filter (group) -> group.slug isnt 'koding'

        { groupsController } = kd.singletons
        currentGroup = groupsController.getCurrentGroup()
        groups = groups.sort (group1, group2) ->
          return -1  if group1.slug is currentGroup.slug
          return 1  if group2.slug is currentGroup.slug
          return -1  if group1.slug < group2.slug
          return 1  if group1.slug > group2.slug
          return 0

        callback null, groups
    options.noItemFoundWidget = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'no-item-found'
      partial  : 'No item found!'

    super options, data
