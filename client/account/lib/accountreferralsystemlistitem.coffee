kd               = require 'kd'
remote           = require('app/remote').getInstance()
KDListItemView   = kd.ListItemView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class AccountReferralSystemListItem extends KDListItemView

  viewAppended: ->
    @getData().isEmailVerified (err, status)=>
      unless (err or status)
        @addSubView editLink = new KDCustomHTMLView
           tagName      : "a"
           partial      : "Mail Verification Waiting"
           cssClass     : "action-link"
  constructor: (options = {}, data)->
    options.tagName ?= 'li'
    super options, data


  partial: (data)->
    """
    <a href="/#{data.profile.nickname}"> #{data.profile.firstName} #{data.profile.lastName} </a>
    """

