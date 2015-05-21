kd                    = require 'kd'
KDView                = kd.View
isKoding              = require 'app/util/isKoding'
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView
TeamMembersCommonView = require './teammemberscommonview'
GroupsBlockedUserView = require '../groupsblockeduserview'


module.exports = class AdminMembersView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    data    = @getData()
    tabView = new KDTabView hideHandleCloseIcons: yes

    tabView.addPane allMembersPane = new KDTabPaneView name: 'All Members'
    tabView.addPane adminsPane     = new KDTabPaneView name: 'Admins'
    tabView.addPane moderatorsPane = new KDTabPaneView name: 'Moderators'

    allMembersPane.addSubView  new TeamMembersCommonView { fetcherMethod: 'fetchMembers'    }, data
    adminsPane.addSubView      new TeamMembersCommonView { fetcherMethod: 'fetchAdmins'     }, data
    moderatorsPane.addSubView  new TeamMembersCommonView { fetcherMethod: 'fetchModerators' }, data

    if isKoding()
      tabView.addPane blockedMembersPane = new KDTabPaneView name: 'Blocked'
      blockedMembersPane.addSubView new GroupsBlockedUserView {}, data

    tabView.showPaneByIndex 0
    @addSubView tabView
