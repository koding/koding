kd = require 'kd'

module.exports = class AccountReferralSystemListItem extends kd.ListItemView

  constructor: (options = {}, data)->
    options.cssClass = "referral-item #{options.cssClass or ''}"
    super options, data

  partial: (data)->

    "
      <div>#{data.friend}</div>
      <div>#{data.status}</div>
      <div>#{data.lastActivity}</div>
      <div>#{data.spaceEarned}</div>
    "
