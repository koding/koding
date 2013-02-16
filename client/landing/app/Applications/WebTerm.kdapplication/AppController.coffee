class WebTermController extends AppController

  KD.registerAppClass @, name : "WebTerm"

  constructor: (options = {}, data) ->

    options.view     = new WebTermView
    options.cssClass = "webterm"

    super options, data

    {view} =  @getOptions()

    view.on "WebTerm.terminated", => @emit "ApplicationWantsToClose", @, view
    view.on 'ViewClosed', =>         @emit "ApplicationWantsToClose", @, view

  bringToFront: ->

    view = new WebTermView
    view.on "WebTerm.terminated", => @emit "ApplicationWantsToClose", @, view
    view.on 'ViewClosed', =>         @emit "ApplicationWantsToClose", @, view

    @emit 'ApplicationWantsToBeShown', @, view,
      name         : "Terminal"
      hiddenHandle : no
      type         : "application"
      cssClass     : "webterm"

WebTerm = {}
