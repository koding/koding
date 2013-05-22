class SidebarController extends KDViewController

  constructor:->
    super

    mainController = @getSingleton 'mainController'
    mainController.on 'ManageRemotes', -> new ManageRemotesModal
    mainController.on 'ManageDatabases', -> new ManageDatabasesModal
    mainController.on 'AccountChanged', @bound 'accountChanged'

    groupsController = @getSingleton 'groupsController'
    groupsController.on 'GroupChanged', @bound 'resetGroupSettingsItem'

    mainController.ready @bound 'accountChanged'

  accountChanged:(account)->
    account or= KD.whoami()
    {profile} = account
    sidebar   = @getView()

    {
     avatar, finderHeader, navController
     avatarAreaIconMenu, finderController
     footerMenuController
    } = sidebar

    avatar.setData account
    finderHeader.setData account
    # temp fix
    # this should be done on framework level
    # check comments on KDObject::setData
    avatar.render()
    finderHeader.render()

    navController.reset()
    footerMenuController.reset()
    @resetAdminNavItems()

    avatarAreaIconMenu.accountChanged account

    finderController.reset()

  resetAdminNavItems:->
    return unless KD.isLoggedIn()

    KD.whoami().fetchRole? (err, role)=>
      if role is "super-admin"
        @getView().navController.addItem
          title    : "Admin Panel"
          type     : "admin"
          loggedIn : yes
          callback : -> new AdminModal

    @resetGroupSettingsItem()

  resetGroupSettingsItem:->
    return unless KD.isLoggedIn()

    do =>
      {navController} = @getView()
      groupsController = @getSingleton 'groupsController'
      group = groupsController.getCurrentGroup()

      # We need to fix that, it happens when you logged-in from entryPoint
      return unless group

      group.fetchMyRoles (err, roles)=>
        if err
          console.warn err
        else if 'admin' in roles
          navController.removeItem dashboardLink  if @dashboardLink?
          @dashboardLink = navController.addItem
            title     : 'Group Settings'
            type      : 'admin'
            loggedIn  : yes
            callback  : ->
              slug = if group.slug is 'koding' then '/' else "/#{group.slug}/"
              KD.getSingleton('router').handleRoute "#{slug}Dashboard"