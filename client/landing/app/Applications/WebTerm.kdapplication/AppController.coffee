class WebTermController extends AppController

  KD.registerAppClass @,
    name         : "WebTerm"
    route        : "Develop"
    multiple     : yes
    hiddenHandle : no

  constructor:(options = {}, data)->

    options.view    = new WebTermAppView
    options.appInfo =
      name         : "Terminal"
      type         : "application"
      cssClass     : "webterm"

    super options, data

WebTerm = {}
