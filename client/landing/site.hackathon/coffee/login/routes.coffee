do ->

  handler = (callback)-> (options) ->
    cb = (app) -> callback app, options
    return KD.singletons.router.clear()  if KD.isLoggedIn()
    KD.singletons.router.openSection 'Login', null, null, cb

  redirect = (route) -> (options) -> KD.singletons.router.handleRoute "/Hackathon#{route}"

  KD.registerRoutes 'Login',
    '/Hackathon/Login'    : handler (app, options)->
      app.getView().animateToForm 'login'
      app.handleQuery options
    '/Hackathon/Register' : handler (app, options)->
      app.getView().animateToForm 'register'
      app.handleQuery options
    '/Hackathon/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
    '/Hackathon/Reset'            : handler (app)-> app.getView().animateToForm 'reset'
    '/Hackathon/ResendToken'      : handler (app)-> app.getView().animateToForm 'resendEmail'
    '/Hackathon/Recover'          : handler (app)-> app.getView().animateToForm 'recover'
    '/Login'                 : redirect '/Login'
    '/Register'              : redirect '/Register'
    '/Redeem'                : redirect '/Redeem'
    '/Reset'                 : redirect '/Reset'
    '/ResendToken'           : redirect '/ResendToken'
    '/Recover'               : redirect '/Recover'
