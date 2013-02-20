class WebTermController extends AppController

  KD.registerAppClass @, name : "WebTerm"

  bringToFront: ->
    view = new WebTermAppView
    
	view.on "WebTerm.terminated", => log "WebTerm.terminated"
    view.on 'WebTermAppViewWantsToClose', => log 'WebTermAppViewWantsToClose'

    @emit "ApplicationWantsToBeShown", @, view,
      name         : "Terminal"
      hiddenHandle : no
      type         : "application"
      cssClass     : "webterm"

WebTerm = {}
