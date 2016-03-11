$                     = require 'jquery'
kd                    = require 'kd'
KDListView            = kd.ListView
AccountEditorListItem = require './accounteditorlistitem'


module.exports = class AccountEditorList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountEditorListItem
    ,options
    super options,data
