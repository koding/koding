class EnvironmentsAppController extends AppController

  KD.registerAppClass this,
    name         : "Environments"
    route        : "/:name?/Environments"
    behavior     : "application"
    enforceLogin : yes

  constructor:(options = {}, data)->

    options.view    = new EnvironmentsMainScene
      cssClass      : "environments split-layout"
    options.appInfo =
      name          : "Environments"

    super options, data
