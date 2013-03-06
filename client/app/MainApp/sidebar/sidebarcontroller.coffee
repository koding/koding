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

    @utils.wait 5000, =>
      KD.whoami().fetchRole? (err, role)=>
        if role is "super-admin"
          @getView().navController.addItem
            title    : "Admin Panel"
            type     : "admin"
            loggedIn : yes
            callback : -> new AdminModal
