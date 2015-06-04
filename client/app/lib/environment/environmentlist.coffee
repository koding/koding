kd                  = require 'kd'

showError           = require 'app/util/showError'
EnvironmentListItem = require './environmentlistitem'


module.exports = class EnvironmentList extends kd.ListView

  constructor: (options = {}, data) ->

    options.itemClass ?= EnvironmentListItem

    super options, data
