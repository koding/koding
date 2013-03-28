class StartTabAppController extends AppController

  KD.registerAppClass @,
    name         : "StartTab"
    route        : "Develop"
    behavior     : "application"
    multiple     : yes

  constructor:(options = {}, data)->

    options.view    = new StartTabMainView
    options.appInfo =
      type          : 'application'
      title         : 'Your Apps'

    super options, data