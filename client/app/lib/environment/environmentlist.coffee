kd                  = require 'kd'
EnvironmentListItem = require './environmentlistitem'


module.exports = class EnvironmentList extends kd.ListView

  constructor: (options = {}, data) ->

    options.itemClass ?= EnvironmentListItem

    super options, data
