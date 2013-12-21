class WebTermController extends AppController

  KD.registerAppClass this,
    name         : "Terminal"
    title        : "Terminal"
    navItem      :
      title      : "Terminal"
      order      : 41
      path       : "/Terminal"
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
    commands     :
      'clear buffer'  : -> console.log 'clearing the buffer'
      'ring bell'     : -> console.log 'ringing the bell'
      'noop'          : -> console.log 'not doing shiiiit'
    keyBindings  : [
      { command: 'clear buffer',  binding: 'super+k',             global: yes }
      { command: 'ring bell',     binding: 'alt+super+k',         global: yes }
      { command: 'noop',          binding: ['super+v','super+r'], global: yes }
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

    @registerKeyBindings 'Terminal'

    KD.mixpanel "Opened Webterm tab", {vmName}

  handleQuery: (query) ->
    @getView().ready =>
      @getView().handleQuery query


WebTerm = {}
