kd                 = require 'kd'
LogsListController = require './logslistcontroller'


module.exports = class LogsListView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass   = 'logs-commonview'
    options.itemLimit ?= 20

    super options, data

  viewAppended: ->

    @listController = new LogsListController { scope : @getOption 'scope' }
    @listView       = @listController.getView()

    @addSubView @listView


  reload: -> @listController.loadItems()
