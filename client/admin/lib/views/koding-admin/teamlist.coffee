kd           = require 'kd'
showError    = require 'app/util/showError'
TeamListItem = require './teamlistitem'


module.exports = class TeamList extends kd.ListView

  constructor: (options = {}, data) ->

    options.itemClass ?= TeamListItem
    super options, data


  toggleDetails: (item) ->

    item.toggleDetails()

    if @_currentItem?.getId() is item.getId()
      @_currentItem = null
    else
      @_currentItem?.toggleDetails()
      @_currentItem = item
