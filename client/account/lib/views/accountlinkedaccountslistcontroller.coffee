kd                    = require 'kd'
globals               = require 'globals'
KodingListController  = require 'app/kodinglist/kodinglistcontroller'


module.exports = class AccountLinkedAccountsListController extends KodingListController

  constructor: (options = {}, data) ->

    options.fetcherMethod = (query, options, callback) ->

      items = []
      for own provider, { nicename } of globals.config.externalProfiles
        items.push { title : nicename, provider }

      callback null, items

    super options, data
