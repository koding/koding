class WebTermController extends AppController
  constructor: (options = {}, data) ->
    options.view = new WebTermView
    @tabHandle = new KDView
    @tabHandle.domElement = $("<b>Terminal</b><span class='terminal icon'></span>")
    super options, data

  bringToFront: ->
    super
      name: 'WebTerm'
      type: 'application'
      tabHandleView: @tabHandle
      hiddenHandle: no

WebTerm = {}
