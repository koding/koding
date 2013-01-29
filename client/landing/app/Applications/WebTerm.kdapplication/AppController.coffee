class WebTermController extends AppController

  constructor: (options = {}, data) ->

    options.view     = new WebTermView
    options.cssClass = "webterm"

    super options, data

    {view} =  @getOptions()

    view.on "WebTerm.terminated", =>
      @propagateEvent
       KDEventType  : "ApplicationWantsToClose"
       globalEvent  : yes
      , data: view

    view.on 'ViewClosed', =>
      @propagateEvent
        KDEventType : 'ApplicationWantsToClose'
        globalEvent : yes
      ,
        data : view

  bringToFront: ->

    data = new WebTermView
    data.on "WebTerm.terminated", =>
      @propagateEvent
       KDEventType  : "ApplicationWantsToClose"
       globalEvent  : yes
      , data: data

    data.on 'ViewClosed', =>
      @propagateEvent
        KDEventType : 'ApplicationWantsToClose'
        globalEvent : yes
      ,
        data : data

    options =
      name         : "Terminal"
      hiddenHandle : no
      type         : "application"
      cssClass     : "webterm"

    @propagateEvent
      KDEventType  : "ApplicationWantsToBeShown"
      globalEvent  : yes
    , {options, data}

WebTerm = {}
