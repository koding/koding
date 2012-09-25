class WebTermController extends AppController
  constructor: (options = {}, data) ->
    options.view = new WebTermView
    options.cssClass = "webterm"
    super options, data

  bringToFront: ->
    mainView = @getSingleton('mainView')
    terminalView = new WebTermView
    terminalView.tabPane = mainView.mainTabView.createTabPane
      name: "Terminal"
      type: "application"
      cssClass: "webterm"
      hiddenHandle: no
    , terminalView

WebTerm = {}
