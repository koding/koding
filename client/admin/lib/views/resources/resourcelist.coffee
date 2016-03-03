kd               = require 'kd'
showError        = require 'app/util/showError'

ResourceListItem = require './resourcelistitem'


module.exports = class ResourceList extends kd.ListView

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
