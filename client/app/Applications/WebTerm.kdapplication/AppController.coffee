class WebTermController extends AppController

  KD.registerAppClass @,
    name         : "WebTerm"
    route        : "Develop"
    multiple     : yes
    hiddenHandle : no
    behavior     : "application"

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

  # TODO: the below was pasted in here during a merge.  fixme C.T.
  bringToFront: ->
    appStorage = new AppStorage 'WebTerm', '1.0'
    appStorage.fetchStorage =>
      data = new WebTermView appStorage
      data.on "WebTerm.terminated", =>
        @propagateEvent
          KDEventType : "ApplicationWantsToClose"
          globalEvent : yes
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
