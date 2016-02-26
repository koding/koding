$                     = require 'jquery'
kd                    = require 'kd'
KDListView            = kd.ListView
AccountSshKeyListItem = require './accountsshkeylistitem'


module.exports = class AccountSshKeyList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      itemClass  : AccountSshKeyListItem
    ,options
    super options,data
