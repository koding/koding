do ->
  routes = [
    '/:name/'
    '/:name?/Groups'
    '/:name?/Groups/Search'
    '/:name?/Members'
    '/:name?/Members/Search'
    '/:name?/Activity/:slug'
    '/:name?/Activity/:slug/Reply/:replySlug'
    '/:name?/Login'
    '/:name?/Logout'
    '/:name?/Join'
    '/:name?/Part'
    '/:name?/Topics'
    '/:name?/Topics/:slug'
    '/:name?/Topics/Search'
    '/:name?/Develop'
    '/:name?/Apps'
    '/:name?/Apps/:appSlug'
    '/:name?/Apps/Search'
    '/:name?/Activity/Search'
    '/:name?/Recover/:recoveryToken'
    '/:name?/Invitation/:inviteToken'
    '/:name?/Verify/:confirmationToken'
  ]
  if window?
    window.KODING_ROUTES = routes
  else if exports?
    exports.routes = routes