class StartTabAppController extends AppController

  KD.registerAppClass @,
    name         : "StartTab"
    route        : "Develop"
    multiple     : yes

  constructor:(options = {}, data)->

    options.view    = new StartTabMainView
    options.appInfo =
      type          : 'application'
      name          : 'Your Apps'

    super options, data