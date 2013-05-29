class StartTabAppController extends AppController

  KD.registerAppClass this,
    name         : "StartTab"
    route        : "/Develop"
    behavior     : "application"
    multiple     : yes
    preCondition :
      condition  : (options, cb)->
        cb KD.isLoggedIn()
      failure    : (options, cb)->
        KD.requireLogin onFailMsg: 'Login to start...' # getSingleton('router').handleRoute "/Activity"

  constructor:(options = {}, data)->

    options.view    = new StartTabMainView
    options.appInfo =
      type          : 'application'
      title         : 'Your Apps'

    super options, data