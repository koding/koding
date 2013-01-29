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

    navController.reset()
    accNavController.reset()
    footerMenuController.reset()
    sidebar.resetAdminNavController()

    avatarAreaIconMenu.accountChanged account

    finderController.reset()
