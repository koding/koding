kd      = require 'kd'
timeago = require 'timeago'

module.exports = class AccountReferralSystemListItem extends kd.ListItemView

  constructor: (options = {}, data)->
    options.cssClass = "referral-item #{options.cssClass or ''}"
    super options, data

    @setClass 'waiting'  unless @getData().confirmed

  partial: (reward)->

    if reward.providedBy?
      {firstName, lastName, nickname} = reward.providedBy.profile
      friend = "#{firstName or nickname} #{lastName}</br><span>@#{nickname}</span>"
    else
      friend = "a Koding user</br>&nbsp;"

    status = if reward.confirmed then 'Claimed' else 'Waiting'

    "
      <div>#{friend}</div>
      <div>#{status}</div>
      <div>#{timeago reward.createdAt}</div>
      <div>#{reward.amount} #{reward.unit}</div>
    "
