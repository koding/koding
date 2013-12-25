class WebTermController extends AppController

  KD.registerAppClass this,
    name         : "Terminal"
    title        : "Terminal"
    route        :
      slug       : "/:name?/Terminal"
      handler    : ({params:{name}, query})->
        # KD.utils.wait 800, ->
        router = KD.getSingleton 'router'
        router.openSection "Terminal", name, query
    multiple     : yes
    hiddenHandle : no
    menu         :
      width      : 250
      items      : [
        {title: "customViewAdvancedSettings"}
      ]
    behavior     : "application"

  constructor:(options = {}, data)->
    params              = options.params or {}
    {joinUser, session} = params
    vmName              = params.vmName  or KD.getSingleton("vmController").defaultVmName
    options.view        = new WebTermAppView { vmName, joinUser, session }
    options.appInfo     =
      title             : "Terminal on #{vmName}"
      cssClass          : "webterm"

    super options, data

    KD.mixpanel "Open Webterm tab, success", {vmName}

  handleQuery: (query) ->
    @getView().ready =>
      @getView().handleQuery query


WebTerm = {}
