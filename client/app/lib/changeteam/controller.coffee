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
        callback null, groups

    super options, data
