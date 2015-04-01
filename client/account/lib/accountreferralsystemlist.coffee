kd                            = require 'kd'
KDListView                    = kd.ListView
AccountReferralSystemListItem = require './accountreferralsystemlistitem'


module.exports = class AccountReferralSystemList extends KDListView

  constructor: (options = {}, data)->

    options.tagName   ?= 'ul'
    options.itemClass ?= AccountReferralSystemListItem

    super options,data
