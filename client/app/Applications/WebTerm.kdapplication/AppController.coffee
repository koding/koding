class WebTermController extends AppController

  KD.registerAppClass @,
    name         : "WebTerm"
    route        : "/Develop"
    multiple     : yes
    hiddenHandle : no
    behavior     : "application"
    preCondition :
      condition  : (cb)->
        KD.singletons.vmController.info (err, info)=>
          cb if info?.state is 'RUNNING' then yes else no
      failure    : (cb)->
        KD.singletons.vmController.askToTurnOn 'WebTerm', cb

  constructor:(options = {}, data)->

    options.view    = new WebTermAppView
    options.appInfo =
      title        : "Terminal"
      cssClass     : "webterm"

    super options, data

  # TODO: the below was pasted in here during a merge.  fixme C.T.
  # bringToFront: ->
  #   appStorage = new AppStorage 'WebTerm', '1.0'
  #   appStorage.fetchStorage =>
  #     data = new WebTermView appStorage
  #     data.on "WebTerm.terminated", =>
  #       @propagateEvent
  #         KDEventType : "ApplicationWantsToClose"
  #         globalEvent : yes
  #       , data: data

  #     data.on 'ViewClosed', =>
  #       @propagateEvent
  #         KDEventType : 'ApplicationWantsToClose'
  #         globalEvent : yes
  #       ,
  #         data : data

  #     options =
  #       name         : "Terminal"
  #       hiddenHandle : no
  #       type         : "application"
  #       cssClass     : "webterm"

  #     @propagateEvent
  #       KDEventType  : "ApplicationWantsToBeShown"
  #       globalEvent  : yes
  #     , {options, data}

WebTerm = {}
