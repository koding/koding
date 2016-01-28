do ->

  handler = (callback)-> (options) ->
    cb = (app) -> callback app, options
    return KD.singletons.router.clear()  if KD.isLoggedIn()
    KD.singletons.router.openSection 'Login', null, null, cb

  redirect = (route) -> (options) -> KD.singletons.router.handleRoute "/Hackathon2014#{route}"

  KD.registerRoutes 'Login',
    '/Hackathon2014/Login'    : handler (app, options)->
      app.getView().animateToForm 'login'
      app.handleQuery options
    '/Hackathon2014/Register' : handler (app, options)->
      app.getView().animateToForm 'register'
      app.handleQuery options
    '/Hackathon2014/Redeem'           : handler (app)-> app.getView().animateToForm 'redeem'
    '/Hackathon2014/Reset'            : handler (app)-> app.getView().animateToForm 'reset'
    '/Hackathon2014/ResendToken'      : handler (app)-> app.getView().animateToForm 'resendEmail'
    '/Hackathon2014/Recover'          : handler (app)-> app.getView().animateToForm 'recover'
    '/Hackathon2014/Apply'            : ->
      return KD.singletons.router.clear()  unless KD.isLoggedIn()
      KD.singletons.router.openSection 'Home', null, null, (app) ->
        app.getView().apply()

    '/Login'                 : redirect '/Login'
    '/Register'              : redirect '/Register'
    '/Redeem'                : redirect '/Redeem'
    '/Reset'                 : redirect '/Reset'
    '/ResendToken'           : redirect '/ResendToken'
    '/Recover'               : redirect '/Recover'
