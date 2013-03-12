# uncomplicate this - Sinan 7/2012
# rewriting this - Sinan 2/2013

class ApplicationManager extends KDObject

  manifestsFetched = no

  ###

  * EMITTED EVENTS
    - AppDidInitiate              [appController, appView, appOptions]
    - AppDidShow                  [appController, appView, appOptions]
    - AppDidQuit                  [appOptions]
    - AppManagerWantsToShowAnApp  [appController, appView, appOptions]
  ###

  constructor:->

    super

    @appControllers = {}
    @frontApp       = null
    @defaultApps    =
      text  : "Ace"
      video : "Viewer"
      image : "Viewer"
      sound : "Viewer"
    @on 'AppManagerWantsToShowAnApp', @bound "setFrontApp"

  open: do ->

    createOrShow = (appOptions, callback = noop)->

      appManager  = KD.getSingleton "appManager"
      {name}      = appOptions
      appInstance = appManager.get name
      cb          = -> appManager.show appOptions, callback
      if appInstance then do cb
      else appManager.create name, cb

    (name, options, callback)->

      [callback, options] = [options, callback] if 'function' is typeof options

      options or= {}

      return warn "ApplicationManager::open called without an app name!"  unless name

      appOptions           = KD.getAppOptions name
      defaultCallback      = -> createOrShow appOptions, callback
      kodingAppsController = @getSingleton("kodingAppsController")

      {multiple, openWith} = appOptions

      unless options.thirdParty
        # if there is no registered appController
        # we assume it should be a 3rd party app
        # that's why it should be run via kodingappscontroller
        if not appOptions?
          @fetchManifests =>
            kodingAppsController.runApp (KD.getAppOptions name), callback
          return

      if appOptions.multiple

        if options.forceNew or appOptions.openWith is "forceNew"
          @create name, (appInstance)=> @showInstance appInstance, callback
          return

        switch appOptions.openWith
          when "lastActive" then do defaultCallback
          when "prompt"
            log "prompting"
            if @appControllers[name]?.instances.length > 1
              log "more than one, namely", @appControllers[name].instances.length
              @createPromptModal appOptions, (appInstanceIndex, openNew)=>
                if typeof appInstanceIndex is "number"
                  appInstance = @appControllers[name].instances[appInstanceIndex]
                  # user selected appInstance to open
                  @show appInstance, callback
                else if openNew
                  # user wants to open a fresh instance
                  @create name, callback
                else
                  warn "user cancelled app to open"
            else do defaultCallback
      else do defaultCallback

  fetchManifests:(callback)->

    @getSingleton("kodingAppsController").fetchApps (err, manifests)->
      manifestsFetched = yes
      for name, manifest of manifests

        manifest.route        = "Develop"
        manifest.behavior   or= "application"
        manifest.thirdParty or= yes

        KD.registerAppClass KodingAppController, manifest

      callback?()


  openFile:(file)->

    type = FSItem.getFileType file.getExtension()

    switch type
      when 'code','text','unknown'
        log "open with a text editor"
        @open @defaultApps.text, (appController)-> appController.openFile file
      when 'image'
        log "open with an image processing app"
      when 'video'
        log "open with a video app"
      when 'sound'
        log "open with a sound app"
      when 'archive'
        log "extract the thing."


  tell:(name, command, rest...)->

    return warn "ApplicationManager::tell called without an app name!"  unless name

    log "::: Telling #{command} to #{name}"

    app = @get name
    cb  = (appInstance)->
      log command, rest
      appInstance?[command]? rest...

    if app then cb app
    else @create name, cb

  create:(name, callback)->

    AppClass   = KD.getAppClass name
    appOptions = KD.getAppOptions name
    log "::: Creating #{name}"
    @register appInstance = new AppClass appOptions  if AppClass
    callback? appInstance

    return appInstance

  show:(appOptions, callback)->

    return if appOptions.background

    appInstance = @get appOptions.name
    appView     = appInstance.getView?()

    return unless appView

    log "::: Show #{appOptions.name}"

    if KD.isLoggedIn()
      @emit 'AppManagerWantsToShowAnApp', appInstance, appView, appOptions
      @setLastActiveIndex appInstance
      callback? appInstance
    else
      KD.getSingleton('router').handleRoute '/', replaceState: yes

  showInstance:(appInstance, callback)->

    appView    = appInstance.getView?() or null
    appOptions = KD.getAppOptions appInstance.getOption "name"

    return if appOptions.background

    if KD.isLoggedIn()
      @emit 'AppManagerWantsToShowAnApp', appInstance, appView, appOptions
      @setLastActiveIndex appInstance
      callback? appInstance
    else
      KD.getSingleton('router').handleRoute '/', replaceState: yes

  quit:(appInstance, callback = noop)->

    @unregister appInstance
    callback()

  quitAll:->
    for own name, apps of @appControllers
      @quit app  for app in apps

  get:(name)-> @appControllers[name]?.first or null

    if apps = @appControllers[name]
      apps.instances[apps.lastActiveIndex] or apps.instances.first
    else
      null

  getByView: (view)->

    appInstance = null
    for name, apps of @appControllers
      for appController in apps.instances
        if view.getId() is appController.getView?()?.getId()
          appInstance = appController
          break
      break if appInstance

    return appInstance

  getFrontApp:-> @frontApp

  setFrontApp:(appInstance)->

    @setLastActiveIndex appInstance
    @frontApp = appInstance

  register:(appInstance)->

    name = appInstance.getOption "name"
    @appControllers[name] ?=
      instances       : []
      lastActiveIndex : null

    @appControllers[name].instances.push appInstance
    @setListeners appInstance

  unregister:(appInstance)->

    name  = appInstance.getOption "name"
    index = @appControllers[name].instances.indexOf appInstance

    if index >= 0
      @appControllers[name].instances.splice index, 1
      if @appControllers[name].instances.length is 0
        delete @appControllers[name]
      appInstance.destroy()

  createPromptModal:(appOptions, callback)->
    # show modal and wait for response
    {name} = appOptions
    selectOptions = for instance, i in @appControllers[name].instances
      title : "#{instance.getOption('name')} (#{i+1})"
      value : i

    modal = new KDModalViewWithForms
      title                 : "Open with:"
      tabs                  :
        navigable           : no
        forms               :
          openWith          :
            callback        : (formOutput)->
              log formOutput, "openWith ::::::"
              modal.destroy()
              {index, openNew} = formOutput
              callback index, openNew
            fields          :
              instance      : {
                label       : "Instance:"
                itemClass   : KDSelectBox
                name        : "index"
                type        : "select"
                defaultValue: selectOptions.first.value
                selectOptions
              }
              newOne        :
                label       : "Open new app:"
                itemClass   : KDOnOffSwitch
                name        : "openNew"
                defaultValue: no
            buttons         :
              Open          :
                cssClass    : "modal-clean-green"
                type        : "submit"
              Cancel        :
                cssClass    : "modal-cancel"
                callback    : ->
                  modal.cancel()
                  callback null

  setListeners:(appInstance)->

    appView = appInstance.getView?()
    appView?.once "KDObjectWillBeDestroyed", =>
      @unregister appInstance

  setLastActiveIndex:(appInstance)->

    return unless appInstance

    if optionSet = @appControllers[appInstance.getOption "name"]
      index = optionSet.instances.indexOf appInstance
      if index is -1 then optionSet.lastActiveIndex = null
      else optionSet.lastActiveIndex = index





  # setGroup:-> console.log 'setGroup', arguments

  # openFileWithApplication:(file, appPath)->
  #   @open appPath, no, (app)->
  #     app.openFile file

  # temp
  notification = null

  notify:(msg)->

    notification.destroy() if notification

    notification = new KDNotificationView
      title     : msg or "Currently disabled!"
      type      : "mini"
      duration  : 2500











  # deprecate these

  # fetchStorage: (appId, version, callback) ->
  #   # warn "System still trying to access application storage for #{appId}"
  #   KD.whoami().fetchStorage {appId, version}, (error, storage) =>
  #     unless storage
  #       storage = {appId,version,bucket:{}} # creating a fake storage
  #     callback error, storage