class WebTermController extends AppController

  KD.registerAppClass this,
    name         : "WebTerm"
    route        : "/Develop"
    multiple     : yes
    hiddenHandle : no
    behavior     : "application"
    preCondition :
      condition  : (options, cb)->
        {params} = options
        vmName   = params?.vmName or "koding~#{KD.nick()}~0"
        KD.singletons.vmController.info vmName, (err, vm, info)=>
          cb  if info?.state is 'RUNNING' then yes else no
      failure    : (options, cb)->
        KD.singletons.vmController.askToTurnOn 'Terminal', cb

  constructor:(options = {}, data)->
    vmName          = options.params?.vmName or "koding~#{KD.nick()}~0"
    options.view    = new WebTermAppView {vmName}
    options.appInfo =
      title         : "Terminal on #{vmName}"
      cssClass      : "webterm"

    super options, data

WebTerm = {}
