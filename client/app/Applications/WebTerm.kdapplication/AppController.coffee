class WebTermController extends AppController

  KD.registerAppClass @,
    name         : "WebTerm"
    route        : "/Develop"
    multiple     : yes
    hiddenHandle : no
    behavior     : "application"
    preCondition :
      condition  : (options, cb)->
        KD.singletons.vmController.info (err, vm, info)=>
          cb  if info?.state is 'RUNNING' then yes else no
      failure    : (options, cb)->
        KD.singletons.vmController.askToTurnOn 'WebTerm', cb

  constructor:(options = {}, data)->
    vmName          = options.params?.vmName or \
                      KD.singletons.vmController.getDefaultVmName()
    options.view    = new WebTermAppView {vmName}
    options.appInfo =
      title         : "Terminal on #{vmName}"
      cssClass      : "webterm"

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
