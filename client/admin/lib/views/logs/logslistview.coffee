kd                 = require 'kd'
LogsList           = require './logslist'
LogsListController = require './logslistcontroller'


module.exports = class LogsListView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass   = 'logs-commonview'
    options.itemLimit ?= 20

    super options, data

  viewAppended: ->

    @list           = new LogsList
    @listController = new LogsListController
      view    : @list
      wrapper : yes
      scope   : @getOption 'scope'

    @listView = @listController.getView()
    @listController.fetchLogs()

    @addSubView @listView


  reload: -> @listController.fetchLogs()