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
      account = whoami()
      queue   = [
        (next) ->
          account.fetchAllParticipatedGroups {}, next
        (next) ->
          account.fetchInviteGroups {}, next
      ]
      async.parallel queue, (err, results) ->
        return  if showError err
        groups = results[0].concat results[1]
        callback null, groups

    super options, data
