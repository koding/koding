kd                    = require 'kd'
isKoding              = require 'app/util/isKoding'
TeamMembersCommonView = require './teammemberscommonview'
GroupsBlockedUserView = require '../groupsblockeduserview'


module.exports = class AdminMembersView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    data    = @getData()
    tabView = new kd.TabView hideHandleCloseIcons: yes

    tabView.addPane all     = new kd.TabPaneView name: 'All Members'
    tabView.addPane admins  = new kd.TabPaneView name: 'Admins'
    tabView.addPane mods    = new kd.TabPaneView name: 'Moderators'

    all.addSubView @allView = new TeamMembersCommonView
      fetcherMethod     : 'fetchMembersWithEmail'
      noItemFoundWidget : new kd.CustomHTMLView
        partial         : 'No members found!'
        cssClass        : 'no-item-view'
    , data

    admins.addSubView @adminsView = new TeamMembersCommonView
      fetcherMethod     : 'fetchAdminsWithEmail'
      noItemFoundWidget : new kd.CustomHTMLView
        partial         : 'No admins found!'
        cssClass        : 'no-item-view'
    , data

    mods.addSubView @modsView = new TeamMembersCommonView
      fetcherMethod     : 'fetchModeratorsWithEmail'
      noItemFoundWidget : new kd.CustomHTMLView
        partial         : 'No moderators found!'
        cssClass        : 'no-item-view'
    , data


    if isKoding()
      tabView.addPane blockedMembersPane = new KDTabPaneView name: 'Blocked'
      blockedMembersPane.addSubView new GroupsBlockedUserView {}, data

    tabView.showPaneByIndex 0
    @addSubView tabView

    @bindRoleChangeEvent()


  bindRoleChangeEvent: ->

    views = [ @allView, @adminsView, @modsView ]

    views.forEach (view) =>
      view.listController.getListView().on 'ItemWasAdded', (item) =>
        item.on 'MemberRoleChanged', (oldRole, newRole) =>
          @listenForRoleChange item, view, oldRole, newRole


  listenForRoleChange: (memberItemView, parentView, oldRole, newRole) ->

    views       = [ @allView, @adminsView, @modsView ]
    becameMod   = oldRole.slug in [ 'admin', 'member' ]    and newRole.slug is 'moderator'
    becameAdmin = oldRole.slug in [ 'moderator', 'member'] and newRole.slug is 'admin'
    targetView  = if becameMod then @modsView else if becameAdmin then @adminsView

    if parentView is @allView
      views.shift() # don't update view on all members tab, it will update itself.

    for view in views
      for memberItem in view.listController.getItemsOrdered()
        if memberItem.data.profile.nickname is memberItemView.data.profile.nickname
          # update member view if it's owner or in all members tab
          if view is @allView or newRole.slug is 'owner'
            memberItem.memberRole = newRole
            memberItem.handleRoleChangeOnUI newRole.label
          else
            # destroy member view, it will be updated and added into new tab.
            memberItem.destroy()

    # change member data and add new one to correct tab
    if targetView
      memberItemView.data.memberRole = newRole
      targetView.listController.addItem memberItemView.data
