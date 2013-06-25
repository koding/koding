class StartTabAppController extends AppController

  KD.registerAppClass this,
    name         : "StartTab"
    route        : "/:name?/Develop"
    behavior     : "application"
    multiple     : yes
    navItem      :
      title      : "Develop"
      path       : "/Develop"
      order      : 50
      role       : 'member'
    # preCondition :
    #   condition  : (options, cb)-> cb KD.isLoggedIn()
    #   failure    : (options, cb)->
    #     KD.requireMembership onFailMsg: 'Login to start...' # getSingleton('router').handleRoute "/Activity"

  constructor:(options = {}, data)->

    options.view    = new StartTabMainView
    options.appInfo =
      type          : 'application'
      title         : 'Your Apps'

    super options, data