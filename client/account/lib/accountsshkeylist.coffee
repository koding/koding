$                     = require 'jquery'
kd                    = require 'kd'
KodingListView        = require 'app/kodinglist/kodinglistview'
AccountSshKeyListItem = require './accountsshkeylistitem'


module.exports = class AccountSshKeyList extends KodingListView

  constructor: (options, data) ->

    options = $.extend
      tagName    : 'ul'
      itemClass  : AccountSshKeyListItem
    , options

    super options, data
