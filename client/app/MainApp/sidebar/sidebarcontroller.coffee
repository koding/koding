class SidebarController extends KDViewController

  accountChanged:(account)->

    {profile} = account
    sidebar   = @getView()
    account or= KD.whoami()

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
    
    do =>
      dashboardLink = null
      {navController} = @getView()
      groupsController = @getSingleton 'groupsController'
      groupsController.on 'GroupChanged', ->
        group = groupsController.getCurrentGroup()
        group.fetchMyRoles (err, roles)=>
          if err
            console.warn err
          else if 'admin' in roles
            navController.removeItem dashboardLink  if dashboardLink?
            dashboardLink = navController.addItem
              title     : 'Admin dashboard'
              type      : 'admin'
              loggedIn  : yes
              callback  : ->
                KD.getSingleton('router').handleRoute "/#{group.slug}/Dashboard"