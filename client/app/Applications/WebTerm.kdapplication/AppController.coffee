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
        vmName   = params?.vmName or (KD.getSingleton 'vmController').defaultVmName
        KD.getSingleton("vmController").info vmName, (err, vm, info)=>
          cb  if info?.state is 'RUNNING' then yes else no
      failure    : (options, cb)->
        KD.getSingleton("vmController").askToTurnOn 'Terminal', cb

  constructor:(options = {}, data)->
    vmName          = options.params?.vmName or (KD.getSingleton 'vmController').defaultVmName
    options.view    = new WebTermAppView {vmName}
    options.appInfo =
      title         : "Terminal on #{vmName}"
      cssClass      : "webterm"

    super options, data

WebTerm = {}
