do ->
  routes = [
    '/Groups'
    '/Groups/Search'
    '/Groups/:group'
    '/Groups/:group/Login'
    '/Groups/:group/Logout'
    '/Groups/:group/Join'
    '/Groups/:group/Part'
    '/Groups/:group/Topics'
    '/Groups/:group/Topics/:topic'
    '/Groups/:group/Topics/Search'
    '/Groups/:group/Members'
    '/Groups/:group/Members/:nickname'
    '/Groups/:group/Members/Search'
    '/Groups/:group/Develop'
    '/Groups/:group/Apps'
    '/Groups/:group/Apps/:app'
    '/Groups/:group/Apps/Search'
    '/Groups/:group/Activity/:slug'
    '/Groups/:group/Activity/Search'
    '/Groups/:group/Recover/:recoveryToken'
    '/Groups/:group/Invitation/:inviteToken'
    '/Groups/:group/Verify/:confirmationToken'
  ]
  if window?
    window.KODING_ROUTES = routes
  else if exports?
    exports.routes = routes