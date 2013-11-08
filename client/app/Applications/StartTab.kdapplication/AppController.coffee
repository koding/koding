class StartTabAppController extends AppController

  KD.registerAppClass this,
    name         : "StartTab"
    route        : "/:name?/Develop"
    behavior     : "application"
    multiple     : no
    navItem      :
      title      : "Develop"
      path       : "/Develop"
      order      : 10
    menu         : [
      { title    : "Make a new App", eventName : "makeANewApp" }
      { title    : "Refresh Apps",   eventName : "refreshApps" }
    ]

  constructor:(options = {}, data)->

    options.view = new StartTabMainView
      testPath : "apps-installed"

    options.appInfo =
      type          : 'application'
      title         : 'Your Apps'

    super options, data