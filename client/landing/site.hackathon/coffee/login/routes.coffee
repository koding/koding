do ->

  handler = (callback)-> (options) ->
    cb = (app) -> callback app, options
    return KD.singletons.router.clear()  if KD.isLoggedIn()
    KD.singletons.router.openSection 'Login', null, null, cb

  redirect = (route) -> (options) -> KD.singletons.router.handleRoute "/WFGH#{route}"

  KD.registerRoutes 'Login',
    '/WFGH/Login'    : handler (app, options)->
      app.getView().animateToForm 'login'
      app.handleQuery options
    '/WFGH/Register' : handler (app, options)->
      app.getView().animateToForm 'register'
      app.handleQuery options
    '/WFGH/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
    '/WFGH/Reset'            : handler (app)-> app.getView().animateToForm 'reset'
    '/WFGH/ResendToken'      : handler (app)-> app.getView().animateToForm 'resendEmail'
    '/WFGH/Recover'          : handler (app)-> app.getView().animateToForm 'recover'
    '/Login'                 : redirect '/Login'
    '/Register'              : redirect '/Register'
    '/Redeem'                : redirect '/Redeem'
    '/Reset'                 : redirect '/Reset'
    '/ResendToken'           : redirect '/ResendToken'
    '/Recover'               : redirect '/Recover'
