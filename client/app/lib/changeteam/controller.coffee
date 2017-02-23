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

        callback null, groups

    options.noItemFoundWidget = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'no-item-found'
      partial  : 'No item found!'

    super options, data
