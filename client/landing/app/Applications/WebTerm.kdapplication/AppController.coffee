class WebTermController extends AppController
  constructor: (options = {}, data) ->
    options.view = new WebTermView
    options.cssClass = "webterm"
    super options, data

  bringToFront: ->
    result = super
      name: "Terminal"
      type: "application"
      cssClass: "webterm"
      hiddenHandle: no
    for entry in result
      @getView().tabPane = entry if entry instanceof KDTabPaneView

WebTerm = {}
