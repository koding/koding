class WebTermController extends AppController

  KD.registerAppClass this,
    name         : "WebTerm"
    navItem      :
      title      : "Develop"
    route        :
      slug       : "/:name?/Develop/Terminal"
      handler     : ({params:{name}, query})->
        vmName   = KD.getSingleton('vmController').defaultVmName
        KD.utils.wait 3000, ->
          router = KD.getSingleton 'router'
          warn "webterm handling itself", name, query, arguments
          router.openSection "WebTerm", name, query
    multiple     : yes
    hiddenHandle : no
    menu         : 
      width      : 250
      items      : [
        {title: "customViewAdvancedSettings"}
      ]
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

  handleQuery: (query) ->
    @getView().ready =>
      @getView().handleQuery query


WebTerm = {}
