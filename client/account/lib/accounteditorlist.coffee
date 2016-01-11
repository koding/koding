kd = require 'kd'
KDListView = kd.ListView
AccountEditorListItem = require './accounteditorlistitem'
$ = require 'jquery'


module.exports = class AccountEditorList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountEditorListItem
    ,options
    super options,data
