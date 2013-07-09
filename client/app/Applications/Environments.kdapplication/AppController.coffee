class EnvironmentsAppController extends AppController

  KD.registerAppClass this,
    name         : "Environments"
    route        : "/:name?/Environments"
    hiddenHandle : yes
    # behavior     : "application"
    navItem      :
      title      : "Environments"
      path       : "/Environments"
      role       : "member"

  constructor:(options = {}, data)->

    options.view    = new EnvironmentsMainView
      cssClass      : "environments split-layout"
    options.appInfo =
      name          : "Environments"

    super options, data
