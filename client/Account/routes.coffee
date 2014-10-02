do ->

  handleVerified = ->
    new KDNotificationView title: "Thanks for verifying"
    @clear()

  handleVerificationFailed = ->
    new KDNotificationView title: "Verification failed!"
    @clear()

  handler = (callback)->
    if KD.isLoggedIn()
      appManager = KD.singleton('appManager')
      if appManager.getFrontApp()?.getOption('name') is 'Account'
        callback appManager.getFrontApp()
      else appManager.open 'Account', callback
    else
      KD.singletons.router.handleRoute '/'

  KD.registerRoutes 'Account',
    "/:name?/Account"          : -> KD.singletons.router.handleRoute '/Account/Profile'
    "/:name?/Account/:section" : ({params:{section}})-> handler (app)-> app.openSection section
    "/:name?/Account/Referrer" : -> KD.singletons.router.handleRoute '/'
    "/Verified": handleVerified
    "/VerificationFailed": handleVerificationFailed