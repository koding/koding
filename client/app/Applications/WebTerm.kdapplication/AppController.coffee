class WebTermController extends AppController

  bringToFront: ->
    view = new WebTermAppView
    
    view.on 'WebTermAppViewWantsToClose', => 
      @propagateEvent 
        KDEventType : 'ApplicationWantsToClose',
        globalEvent: yes
      , 
        data: view

    options =
      name         : "Terminal"
      hiddenHandle : no
      type         : "application"
      cssClass     : "webterm"

    @propagateEvent
      KDEventType  : "ApplicationWantsToBeShown"
      globalEvent  : yes
    , 
      options: options,
      data: view

WebTerm = {}
