kd            = require 'kd'
KDView        = kd.View
KDTabView     = kd.TabView
KDTabPaneView = kd.TabPaneView

AdminIntegrationsListView = require './adminintegrationslistview'


module.exports = class AdminMembersView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'integrations'

    super options, data

    @createTabView()


  createTabView: ->

    tabView = new KDTabView hideHandleCloseIcons: yes

    tabView.addPane all        = new KDTabPaneView name: 'All Services'
    tabView.addPane configured = new KDTabPaneView name: 'Configured Integrations'

    all.addSubView        new AdminIntegrationsListView integrationType: 'new'
    configured.addSubView new AdminIntegrationsListView integrationType: 'configured'

    tabView.showPaneByIndex 0
    @addSubView tabView
