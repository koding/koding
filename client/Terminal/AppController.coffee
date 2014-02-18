class WebTermController extends AppController

  KD.registerAppClass this,
    name         : "Terminal"
    title        : "Terminal"
    version      : "1.0.1"
    enforceLogin : yes
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
      'ring bell'     : 'ringBell'
      'noop'          : (->)
    keyBindings  : [
      { command: 'ring bell',     binding: 'alt+super+k',         global: yes }
      { command: 'noop',          binding: ['super+v','super+r'], global: yes }
    ]
    behavior     : "application"

  constructor:(options = {}, data)->
    params              = options.params or {}
    vmName              = params.vmName  or KD.getSingleton("vmController").defaultVmName
    options.view        = (new WebTermAppView { vmName })
                            .on 'command', @bound 'handleCommand'
    options.appInfo     =
      title             : "Terminal on #{vmName}"
      cssClass          : "webterm"

    super options, data

  handleQuery: (query) ->
    @getView().ready =>
      @getView().handleQuery query

  ringBell: do (bell = try new Audio '/a/audio/bell.wav') -> (event) ->
    event?.preventDefault()

    { name, version } = @getOptions()

    storage = (KD.getSingleton 'appStorageController').storage name, version

    if not bell? or storage.getValue 'visualBell'
    then new KDNotificationView title: 'Bell!', duration: 100
    else bell.play()

  runCommand:(command)->
    @getView().ready =>
      @getView().runCommand command
WebTerm = {}
