kd                            = require 'kd'
KDListView                    = kd.ListView
KodingListView                = require 'app/kodinglist/kodinglistview'
AccountLinkedAccountsListItem = require './accountlinkedaccountslistitem'


module.exports = class AccountLinkedAccountsList extends KodingListView

  constructor: (options = {}, data) ->

    options.tagName   or= 'ul'
    options.itemClass or= AccountLinkedAccountsListItem
    options.cssClass    = 'AppModal--account-switchList'

    super options, data
