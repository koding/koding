kd                    = require 'kd'
remote                = require('app/remote').getInstance()
KDView                = kd.View
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView
TeamMembersView       = require './members/teammembersview.coffee'
KDCustomHTMLView      = kd.CustomHTMLView
KDHitEnterInputView   = kd.HitEnterInputView
KDListViewController  = kd.ListViewController


module.exports = class GroupsMemberPermissionsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    @tabView = new KDTabView hideHandleCloseIcons: yes

    @tabView.addPane @allMembersPane     = new KDTabPaneView name: 'All Members'
    @tabView.addPane @adminsPane         = new KDTabPaneView name: 'Admins'
    @tabView.addPane @moderatorsPane     = new KDTabPaneView name: 'Moderators'
    @tabView.addPane @blockedMembersPane = new KDTabPaneView name: 'Blocked'

    @tabView.showPaneByIndex 0
    @allMembersPane.addSubView new TeamMembersView

    @addSubView @tabView
