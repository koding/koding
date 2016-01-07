kd = require 'kd'
KDListView = kd.ListView
AccountKodingKeyListItem = require './accountkodingkeylistitem'


module.exports = class AccountKodingKeyList extends KDListView

  constructor:(options, data)->
    defaults    =
      tagName   : "ul"
      itemClass : AccountKodingKeyListItem
    options = defaults extends options
    super options, data
