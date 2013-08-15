class WebTermController extends AppController

  KD.registerAppClass this,
    name         : "WebTerm"
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
        {vmName} = options
        vmController = KD.getSingleton 'vmController'
        vmController.fetchDefaultVmName (defaultVmName)->
          vmName or= defaultVmName
          return cb no  unless vmName
          vmController.info vmName, (err, vm, info)->
            cb  info?.state is 'RUNNING'
      failure     : (options, cb)->
        KD.getSingleton("vmController").askToTurnOn
          appName : 'WebTerm'
          vmName  : options.vmName
        , cb

  constructor:(options = {}, data)->
    vmName          = options.params?.vmName or (KD.getSingleton 'vmController').defaultVmName
    options.view    = new WebTermAppView {vmName, joinUser: options.params?.joinUser, session: options.params?.session}
    options.appInfo =
      title         : "Terminal on #{vmName}"
      cssClass      : "webterm"

    super options, data

  handleQuery: (query) ->
    @getView().ready =>
      @getView().handleQuery query


WebTerm = {}
