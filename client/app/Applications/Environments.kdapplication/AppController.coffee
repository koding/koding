class EnvironmentsAppController extends AppController

  KD.registerAppClass this,
    name         : "Environments"
    route        : "/:name?/Environments"
    hiddenHandle : no
    behavior     : "application"

  constructor:(options = {}, data)->

    options.view    = new EnvironmentsMainView
      cssClass      : "environments split-layout"
    options.appInfo =
      name          : "Environments"

    super options, data
