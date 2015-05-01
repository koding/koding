kd                    = require 'kd'
remote                = require('app/remote').getInstance()
KDView                = kd.View
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView
TeamMembersView       = require './teammembersview.coffee'
KDCustomHTMLView      = kd.CustomHTMLView
KDHitEnterInputView   = kd.HitEnterInputView
KDListViewController  = kd.ListViewController


module.exports = class AdminMembersView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    @addSubView @tabView = new KDTabView hideHandleCloseIcons: yes

    @tabView.addPane @allMembersPane     = new KDTabPaneView name: 'All Members'
    @tabView.addPane @adminsPane         = new KDTabPaneView name: 'Admins'
    @tabView.addPane @moderatorsPane     = new KDTabPaneView name: 'Moderators'
    @tabView.addPane @blockedMembersPane = new KDTabPaneView name: 'Blocked'

    @tabView.showPaneByIndex 0

    @allMembersPane.addSubView new TeamMembersView {}, @getData()
    @adminsPane.addSubView new TeamMembersView {}, @getData()
    @moderatorsPane.addSubView new TeamMembersView {}, @getData()
    @blockedMembersPane.addSubView new TeamMembersView {}, @getData()
