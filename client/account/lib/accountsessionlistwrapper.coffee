kd                     = require 'kd'
KDView                 = kd.View
KDHeaderView           = kd.HeaderView
AccountSessionListItem = require './accountsessionlistitem'
KodingListController   = require 'app/kodinglist/kodinglistcontroller'
kookies                = require 'kookies'
whoami                 = require 'app/util/whoami'

module.exports = class AccountSessionListWrapper extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @top = new KDView
      cssClass : 'top'

    @top.addSubView @header = new KDHeaderView
      title : 'Active Sessions'

    @listController = new KodingListController
      limit             : 8
      lazyLoadThreshold : 8
      noItemFoundText   : 'You have no active session.'
      itemClass         : AccountSessionListItem
      fetcherMethod     : (query, options, callback) ->
        whoami().fetchMySessions options, (err, sessions)  -> callback err, sessions

    @listController.on 'ItemDeleted', (item) ->
      session  = item.getData()
      clientId = kookies.get 'clientId'

      # if the deleted session is the current one logout user immediately
      if clientId is session.clientId
        kookies.expire 'clientId'
        global.location.replace '/'

    @addSubView @listController.getView()
