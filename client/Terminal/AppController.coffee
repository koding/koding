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

    KD.singletons.vmController._runWrapper 'oskite.All', (err, kontainers)=>
      vms = 0
      limits = 0
      if kontainers
        for own name, kontainer of kontainers
          for own attribute, amount of kontainer
            if attribute is 'activeVMs'
              vms += amount
            if attribute is 'activeVMsLimit'
              limits += amount

      if vms >= limits
        KD.singletons.mainView.createGlobalNotification
          title   : "Sorry, we can't launch your VM right now. We are experiencing an unxpected high load."
          content : "Please try again in 10 minutes."
          type    : 'red'


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
