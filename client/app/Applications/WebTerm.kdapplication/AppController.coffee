class WebTermController extends AppController

  KD.registerAppClass this,
    name         : "WebTerm"
    title        : "Terminal"
    navItem      :
      title      : "Develop"
    route        :
      slug       : "/:name?/Develop/Terminal"
      handler    : ({params:{name}, query})->
        KD.utils.wait 800, ->
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
        KD.mixpanel "Click open Webterm", name

        {vmName} = options
        vmController = KD.getSingleton 'vmController'
        vmController.fetchDefaultVmName (defaultVmName)->
          vmName or= defaultVmName
          return cb no  unless vmName
          vmController.info vmName, KD.utils.getTimedOutCallback (err, vm, info)->
            cb  info?.state is 'RUNNING', {vmName, info}
          , ->
            cb no
            KD.logToExternal "failed to fetch vminfo, couldn't open terminal"
          , 2500
      failure     : (options, cb)->
        {vmName} = options
        KD.mixpanel "Can't open Webterm", {vmName}
        KD.getSingleton("vmController").askToTurnOn
          appName : 'WebTerm'
          vmName  : vmName
          state   : options.info.state
        , cb

  constructor:(options = {}, data)->
    params              = options.params or {}
    {joinUser, session} = params
    vmName              = params.vmName  or KD.getSingleton("vmController").defaultVmName
    options.view        = new WebTermAppView { vmName, joinUser, session }
    options.appInfo     =
      title             : "Terminal on #{vmName}"
      cssClass          : "webterm"

    super options, data

    KD.mixpanel "Opened webterm", {vmName}

  handleQuery: (query) ->
    @getView().ready =>
      @getView().handleQuery query


WebTerm = {}
