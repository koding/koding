kd           = require 'kd'
LogsItemView = require './logsitemview'


module.exports = class LogsList extends kd.ListView

  constructor: (options = {}, data) ->
    options.wrapper   ?= yes
    options.itemClass ?= LogsItemView

    super options, data
