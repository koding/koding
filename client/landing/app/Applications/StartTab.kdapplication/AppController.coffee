class StartTabAppController extends AppController

  KD.registerAppClass @,
    name     : "StartTab"
    multiple : yes

  constructor:(options = {}, data)->

    options.view    = new StartTabMainView
    options.appInfo =
      hiddenHandle  : no
      type          : 'application'
      name          : 'Your Apps'

    super options, data