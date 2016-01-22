kd           = require 'kd'
LogsListView = require './logslistview'


module.exports = class LogsView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related apitokens'

    super options, data

    @createTabView()


  createTabView: ->

    data     = @getData()
    tabView  = new kd.TabView hideHandleCloseIcons: yes

    tabView.tabHandleContainer.addSubView new kd.ButtonView
      cssClass : 'solid compact green add-new'
      title    : 'Reload'
      callback : =>
        @logsListView.listController.fetchLogs()

    logsPane = tabView.addPane new kd.TabPaneView name: 'Logs'

    logsPane.addSubView @logsListView = new LogsListView
      noItemFoundWidget : new kd.CustomHTMLView
        partial         : 'No log found!'
        cssClass        : 'no-item-view'
    , data

    tabView.showPaneByIndex 0
    @addSubView tabView
