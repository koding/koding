class EnvironmentsAppController extends AppController

  KD.registerAppClass @,
    name         : "Environments"
    route        : "/Environments"
    hiddenHandle : yes

  constructor:(options = {}, data)->

    options.view    = new EnvironmentsMainView
      cssClass      : "Environments"
    options.appInfo =
      name          : "Environments"

    super options, data