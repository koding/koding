class WebTermController extends AppController

  KD.registerAppClass @,
    name     : "WebTerm"
    multiple : yes

  constructor:(options = {}, data)->

    options.view    = new WebTermAppView
    options.appInfo =
      name         : "Terminal"
      hiddenHandle : no
      type         : "application"
      cssClass     : "webterm"

    super options, data

WebTerm = {}
