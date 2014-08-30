class HomeAppController extends AppController

  KD.registerAppClass this,
    name         : "Home"
    route        : "/Home"
    preCondition :
      condition  : (options, cb) -> cb !KD.isLoggedIn()
      failure    : (options, cb) ->
        {router} = KD.singletons
        router.handleRoute router.getDefaultRoute()

  constructor:(options = {}, data)->

    options.view    = new HomeView
      cssClass      : "content-page home"

    super options, data
