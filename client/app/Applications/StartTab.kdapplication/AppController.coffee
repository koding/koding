class StartTabAppController extends AppController

  KD.registerAppClass @,
    name         : "StartTab"
    route        : "/Develop"
    behavior     : "application"
    multiple     : yes
    preCondition :
      condition  : (cb)-> cb KD.isLoggedIn()
      failure    : (cb)-> KD.requireLogin onFailMsg: 'Login to start...' # getSingleton('router').handleRoute "/Activity"

  constructor:(options = {}, data)->

    options.view    = new StartTabMainView
    options.appInfo =
      type          : 'application'
      title         : 'Your Apps'

    super options, data