kd            = require 'kd'
KDView        = kd.View
KDTabView     = kd.TabView
KDTabPaneView = kd.TabPaneView

AdminIntegrationsListView           = require './adminintegrationslistview'
AdminConfiguredIntegrationsListView = require './adminconfiguredintegrationslistview'


module.exports = class AdminMembersView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'integrations'

    super options, data

    @createTabView()


  createTabView: ->

    @addSubView tabView = @tabView = new KDTabView hideHandleCloseIcons: yes

    tabView.addPane all        = new KDTabPaneView name: 'All Services'
    tabView.addPane configured = new KDTabPaneView name: 'Configured Integrations'

    @allListView        = new AdminIntegrationsListView           integrationType: 'new'
    @configuredListView = new AdminConfiguredIntegrationsListView integrationType: 'configured'

    all.addSubView @allListView
    configured.addSubView @configuredListView

    tabView.showPaneByIndex 0

    @allListView.on 'ShowConfiguredTab', =>
      tabView.showPaneByIndex 1
      @configuredListView.refresh()


  handleAction: (action) ->

    index = if action is 'Configure' then 1 else 0
    @tabView.showPaneByIndex index
