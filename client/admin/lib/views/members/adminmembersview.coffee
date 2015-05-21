kd                    = require 'kd'
KDView                = kd.View
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView
TeamMembersCommonView = require './teammemberscommonview.coffee'


module.exports = class AdminMembersView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    data    = @getData()
    tabView = new KDTabView hideHandleCloseIcons: yes

    tabView.addPane allMembersPane     = new KDTabPaneView name: 'All Members'
    tabView.addPane adminsPane         = new KDTabPaneView name: 'Admins'
    tabView.addPane moderatorsPane     = new KDTabPaneView name: 'Moderators'
    tabView.addPane blockedMembersPane = new KDTabPaneView name: 'Blocked'

    allMembersPane.addSubView  new TeamMembersCommonView { fetcherMethod: 'fetchMembers'    }, data
    adminsPane.addSubView      new TeamMembersCommonView { fetcherMethod: 'fetchAdmins'     }, data
    moderatorsPane.addSubView  new TeamMembersCommonView { fetcherMethod: 'fetchModerators' }, data
    # blockedMembersPane.addSubView new TeamMembersView {}, data

    tabView.showPaneByIndex 0
    @addSubView tabView
