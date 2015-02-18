kd = require 'kd'
KDListView = kd.ListView
AccountLinkedAccountsListItem = require './accountlinkedaccountslistitem'


module.exports = class AccountLinkedAccountsList extends KDListView

  constructor:(options = {}, data)->

    options.tagName   or= "ul"
    options.itemClass or= AccountLinkedAccountsListItem

    super options,data




