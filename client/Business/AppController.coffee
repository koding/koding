class BusinessAppController extends AppController

  KD.registerAppClass this,
    name         : "Business"
    route        : "/Business"
    preCondition :
      condition  : (options, cb)-> cb !KD.isLoggedIn()
      failure    : (options, cb)-> KD.singletons.router.handleRoute '/Activity'

  constructor:(options = {}, data)->

    options.view    = new BusinessView
      cssClass      : "content-page business"

    super options, data
