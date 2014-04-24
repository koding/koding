class HomeAppController extends AppController

  KD.registerAppClass this,
    name         : "Home"
    route        : "/Home"
    preCondition :
      condition  : (options, cb)-> cb !KD.isLoggedIn()
      failure    : (options, cb)-> KD.singletons.router.handleRoute '/Activity'

  constructor:(options = {}, data)->

    options.view    = new HomeView
      cssClass      : "content-page home"

    super options, data
