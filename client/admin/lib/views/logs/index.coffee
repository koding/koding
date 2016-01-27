kd                     = require 'kd'
LogsListView           = require './logslistview'
AdminSubTabHandleView  = require 'admin/views/customviews/adminsubtabhandleview'


module.exports = class LogsView extends kd.View

  SCOPES   =
    all    : 'All Logs'
    log    : 'Logs'
    info   : 'Infos'
    warn   : 'Warnings'
    error  : 'Errors'

  constructor: (options = {}, data) ->

    options.cssClass = 'logs-related'

    super options, data

    @createTabView()

    @on 'SubTabRequested', (scope, query) =>
      index = (Object.keys SCOPES).indexOf(scope)
      return @setRoute()  if index < 0

      @tabView.showPaneByIndex index

    kd.singletons.notificationController.on 'MemberWarning', =>
      @tabView.showPaneByIndex 0
      @handleReload()


  createTabView: ->

    @tabView = new kd.TabView
      hideHandleCloseIcons : yes
      tabHandleClass       : AdminSubTabHandleView

    @tabView.tabHandleContainer.addSubView new kd.ButtonView
      cssClass : 'solid compact green reload'
      title    : 'Reload'
      callback : @bound 'handleReload'

    Object.keys(SCOPES).forEach (scope) =>
      @tabView.addPane new kd.TabPaneView
        name  : SCOPES[scope]
        route : "/Admin/Logs/#{scope}"
        view  : new LogsListView { scope }
        lazy  : yes

    @tabView.showPaneByIndex 0
    @addSubView @tabView

  setRoute: (route = '') ->
    kd.singletons.router.handleRoute "/Admin/Logs#{route}"

  handleReload: ->
    @tabView.activePane.getMainView().reload()
