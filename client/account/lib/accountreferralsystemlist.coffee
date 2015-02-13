$ = require 'jquery'
kd = require 'kd'
KDListView = kd.ListView
AccountReferralSystemListItem = require './accountreferralsystemlistitem'


module.exports = class AccountReferralSystemList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountReferralSystemListItem
    ,options
    super options,data



