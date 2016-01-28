do ->

  handler = (callback) -> (options) ->
    cb = (app) -> callback app, options
    groupName = KD.utils.getGroupNameFromLocation()

    # we need to remove this and make it selectively only
    # for login and register routes
    # redeem/reset etc should work for groups - SY
    return KD.singletons.router.handleRoute '/'  if groupName isnt 'koding'

    KD.singletons.router.openSection 'Login', null, null, cb


  handleVerified = ->
    new KDNotificationView title: "Thanks for verifying"
    @clear()

  handleVerificationFailed = ->
    new KDNotificationView title: "Verification failed!"
    @clear()

  handleResetRoute = ({params:{token}}) ->
    KD.singletons.router.openSection 'Login', null, null, (app) ->
      app.getView().setCustomDataToForm('reset', {recoveryToken:token})
      app.getView().animateToForm('reset')


  KD.registerRoutes 'Login',

    '/Login/:token?' : handler (app, options)->
      app.getView().animateToForm 'login'
      app.handleQuery options

    '/Register' : handler (app, options)->
      app.getView().animateToForm 'register'
      app.handleQuery options

    '/Redeem'       : handler (app)-> app.getView().animateToForm 'redeem'
    '/Reset/:token' : handleResetRoute
    '/ResendToken'  : handler (app)-> app.getView().animateToForm 'resendEmail'
    '/Recover'      : handler (app)-> app.getView().animateToForm 'recover'

    '/Verified'     : handleVerified

    '/VerificationFailed' : handleVerificationFailed
