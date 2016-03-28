kd               = require 'kd'
showError        = require 'app/util/showError'

KodingListView   = require 'app/kodinglist/kodinglistview'
ResourceListItem = require './resourcelistitem'


module.exports = class ResourceList extends KodingListView

  constructor: (options = {}, data) ->

    options.itemClass ?= ResourceListItem
    super options, data


  toggleDetails: (item) ->

    item.toggleDetails()

    if @_currentItem?.getId() is item.getId()
      @_currentItem = null
    else
      @_currentItem?.toggleDetails()
      @_currentItem = item
