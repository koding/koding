class EnvironmentsAppController extends AppController

  KD.registerAppClass this,
    name         : 'Environments'
    route        : '/:name?/Environments'
    behavior     : 'application'
    preCondition :
      condition  : (options, cb)-> cb KD.isLoggedIn() or KD._isLoggedIn
      failure    : (options, cb)->
        KD.singletons.appManager.open 'Environments', conditionPassed : yes
        KD.showEnforceLoginModal()

  constructor:(options = {}, data)->

    options.view    = new EnvironmentsMainScene
      cssClass      : 'environments split-layout'
    options.appInfo =
      name          : 'Environments'

    super options, data
