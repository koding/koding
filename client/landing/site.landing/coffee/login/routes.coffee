kd    = require 'kd'
utils = require './../core/utils'

do ->

  handler = (callback) -> (options) ->
    cb = (app) -> callback app, options
    groupName = utils.getGroupNameFromLocation()

    # we need to remove this and make it selectively only
    # for login and register routes
    # redeem/reset etc should work for groups - SY
    return kd.singletons.router.handleRoute '/'  if groupName isnt 'koding'

    kd.singletons.router.openSection 'Login', null, null, cb


  handleVerified = ->
    new kd.NotificationView { title: 'Thanks for verifying' }
    @clear()

  handleVerificationFailed = ->
    new kd.NotificationView { title: 'Verification failed!' }
    @clear()

  handleResetRoute = ({ params:{ token } }) ->
    kd.singletons.router.openSection 'Login', null, null, (app) ->
      app.getView().setCustomDataToForm('reset', { recoveryToken:token })
      app.getView().animateToForm('reset')

  handleUnsubscribeEmail = ({ params: { token, email } }) ->
    utils.unsubscribeEmail token, email,
      error   : ->
      success : ->
    new kd.NotificationView { title: 'You are unsubscribed from all email notifications.' }
    @clear()


  kd.registerRoutes 'Login',

    '/Login/:token?' : ->
      groupName = utils.getGroupNameFromLocation()

      utils.checkIfGroupExists groupName, (err, group) ->
        kd.singletons.router.handleRoute if group then '/' else '/Teams'

    '/Register' : ->
      # we don't allow solo registrations anymore - SY
      kd.singletons.router.handleRoute '/Teams'

    '/RegisterForTests' : handler (app, options) ->
      app.getView().animateToForm 'register'
      app.handleQuery options

    # '/Redeem'       : handler (app) -> app.getView().animateToForm 'redeem'
    '/Reset/:token' : handleResetRoute
    '/ResendToken'  : handler (app) -> app.getView().animateToForm 'resendEmail'
    '/Recover'      : handler (app) -> app.getView().animateToForm 'recover'

    '/Verified'     : handleVerified

    '/VerificationFailed' : handleVerificationFailed

    '/Unsubscribe/:token/:email' : handleUnsubscribeEmail
