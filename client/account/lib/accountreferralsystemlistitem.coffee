kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView


module.exports = class AccountReferralSystemListItem extends KDListItemView
  constructor: (options, data)->
    options =
      tagName: "li"
    super options, data

  viewAppended: ->
    @getData().isEmailVerified (err, status)=>
      unless (err or status)
        @addSubView editLink = new KDCustomHTMLView
           tagName      : "a"
           partial      : "Mail Verification Waiting"
           cssClass     : "action-link"

      super

  partial: (data)->
    """
    <a href="/#{data.profile.nickname}"> #{data.profile.firstName} #{data.profile.lastName} </a>
    """

