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
    commands     :
      'clear buffer'  : 'clearBuffer'
      'ring bell'     : 'ringBell'
      'noop'          : (->)
    keyBindings  : [
      { command: 'ring bell',     binding: 'alt+super+k',         global: yes }
      { command: 'noop',          binding: ['super+v','super+r'], global: yes }
    ]
    behavior     : "application"

  constructor:(options = {}, data)->
    params              = options.params or {}
    {joinUser, session} = params
    vmName              = params.vmName  or KD.getSingleton("vmController").defaultVmName
    view                = (new WebTermAppView { vmName, joinUser, session })
                            .on 'command', @bound 'handleCommand'
    options.view        = view
    options.appInfo     =
      title             : "Terminal on #{vmName}"
      cssClass          : "webterm"

    super options, data

    KD.mixpanel "Open Webterm tab, success", {vmName}

  handleQuery: (query) ->
    @getView().ready =>
      @getView().handleQuery query

  ringBell: do (bell = try new Audio '/a/audio/bell.wav') ->
    (event) ->
      { name, version } = @getOptions()
      storage = (KD.getSingleton 'appStorageController').storage name, version
      event?.preventDefault()
      if not bell? or storage.getValue 'visualBell'
      then new KDNotificationView title: 'Bell!', duration: 100
      else bell.play()
  
  runCommand:(command)->
    @getView().ready =>
      @getView().runCommand command
WebTerm = {}
