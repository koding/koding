class WebTermController extends AppController

  KD.registerAppClass @,
    name         : "WebTerm"
    route        : "Develop"
    multiple     : yes
    hiddenHandle : no
    behavior     : "application"

  constructor:(options = {}, data)->

    options.view    = new WebTermAppView
    options.appInfo =
      title        : "Terminal"
      cssClass     : "webterm"

    super options, data

WebTerm = {}
