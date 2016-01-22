kd                 = require 'kd'
remote             = require('app/remote').getInstance()

LogsList           = require './logslist'
LogsListController = require './logslistcontroller'


module.exports = class LogsListView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass   = 'members-commonview'
    options.itemLimit ?= 20

    super options, data

    @createListController()


  createListController: ->

    @list           = new LogsList
    @listController = new LogsListController
      view    : @list
      wrapper : yes

    @listView = @listController.getView()
    @listController.fetchLogs()


  viewAppended: ->

    @addSubView @listView
