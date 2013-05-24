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

    if 'admin' in KD.config.roles
      {navController} = @getView()
      {slug} = KD.config.entryPoint or {slug:'koding'}

      navController.removeItemByTitle 'Group Settings'
      navController.addItem
        title     : 'Group Settings'
        type      : 'admin'
        loggedIn  : yes
        callback  : ->
          slug = if slug is 'koding' then '/' else "/#{slug}/"
          KD.getSingleton('router').handleRoute "#{slug}Dashboard"
