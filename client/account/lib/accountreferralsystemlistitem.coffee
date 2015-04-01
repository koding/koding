kd               = require 'kd'
remote           = require('app/remote').getInstance()
KDListItemView   = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class AccountReferralSystemListItem extends KDListItemView

  constructor: (options = {}, data)->
    options.tagName ?= 'li'
    super options, data


  viewAppended: ->

    {providedBy} = @getData()
    remote.cacheable "JAccount", providedBy, (err, account)=>
      {profile} = account  if account
      @addSubView new KDCustomHTMLView
        partial: err or """
          <a href="/#{profile.nickname}"> #{profile.firstName} #{profile.lastName} </a>
        """
