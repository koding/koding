class SidebarController extends KDViewController

  accountChanged:(account)->

    {profile} = account
    sidebar   = @getView()
    account or= KD.whoami()

    {
     avatar, finderHeader, navController
     accNavController, avatarAreaIconMenu
     finderController, footerMenuController
    } = sidebar

    avatar.setData account
    finderHeader.setData account
    # temp fix
    # this should be done on framework level
    # check comments on KDObject::setData
    avatar.render()
    finderHeader.render()

    navController.reset()
    accNavController.reset()
    footerMenuController.reset()
    sidebar.resetAdminNavController()

    avatarAreaIconMenu.accountChanged account

    finderController.reset()
