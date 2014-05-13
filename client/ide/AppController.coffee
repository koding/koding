class IDEAppController extends AppController

  KD.registerAppClass this,
    name         : "IDE"
    route        : "/:name?/IDE"
    behavior     : "application"
    preCondition :
      condition  : (options, cb)-> cb KD.isLoggedIn()
      failure    : (options, cb)->
        KD.singletons.appManager.open 'IDE', conditionPassed : yes
        KD.showEnforceLoginModal()

  constructor: (options = {}, data) ->
    options.view    = new IDEAppView
    options.appInfo =
      type          : "application"
      name          : "IDE"

    super options, data
