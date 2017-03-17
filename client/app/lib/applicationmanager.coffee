$                    = require 'jquery'
async                = require 'async'
globals              = require 'globals'
getAppOptions        = require './util/getAppOptions'
getAppClass          = require './util/getAppClass'
kd                   = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView   = kd.NotificationView
KDObject             = kd.Object
KDOnOffSwitch        = kd.OnOffSwitch
KDSelectBox          = kd.SelectBox
KDView               = kd.View
FSHelper             = require './util/fs/fshelper'
KodingAppsController = require './kodingappscontroller'

module.exports =

class ApplicationManager extends KDObject

  ###

  * EMITTED EVENTS
    - AppCreated                  [appController]
    - AppIsBeingShown             [appController, appView, appOptions]
  ###

  constructor: ->

    super()

    @appControllers = {}
    @frontApp       = null
    @defaultApps    =
      text  : 'Ace'
      video : 'Viewer'
      image : 'Viewer'
      sound : 'Viewer'

    @on 'AppIsBeingShown', @bound 'setFrontApp'


  isAppInternal: (name = '') -> globals.config.apps[name]?


  isAppLoaded: (name = '') -> (name in Object.keys globals.appClasses)


  shouldLoadApp: (name = '') -> (@isAppInternal name) and not (@isAppLoaded name)


  open: do ->

    createOrShow = (appOptions = {}, appParams, callback = kd.noop) ->

      name = appOptions?.name
      return @handleAppNotFound()  unless name

      appInstance = @get name
      cb = if appParams.background or appOptions.background
      then (appInst) -> kd.utils.defer -> callback appInst
      else @show.bind this, name, appParams, callback

      if appInstance then cb appInstance else @create name, appParams, cb

    (name, options, callback) ->

      return kd.warn 'ApplicationManager::open called without an app name!'  unless name

      [callback, options]  = [options, callback] if 'function' is typeof options
      options            or= {}
      appOptions           = getAppOptions name
      appParams            = options.params or {}
      defaultCallback      = createOrShow.bind this, appOptions, appParams, callback

      # If app has a preCondition then first check condition in it
      # if it returns true then continue, otherwise call failure
      # method of preCondition if exists

      if appOptions?.preCondition? and not options.conditionPassed

        if appOptions.preCondition.checkOnLoadOnly
          if @get name then return do defaultCallback

        appOptions.preCondition.condition appParams, (state, newParams) =>
          if state
            options.conditionPassed = yes
            options.params = newParams  if newParams
            @open name, options, callback
          else
            params = newParams or appParams
            appOptions.preCondition.failure? params, callback
        return

      # if there is no registered appController
      # we assume it should be a 3rd party app
      # that's why it should be run via kodingAppsController

      if not appOptions? and not options.avoidRecursion?

        if @shouldLoadApp name
          return KodingAppsController.loadInternalApp name, (err) =>
            return kd.warn err  if err
            kd.utils.defer => @open name, options, callback

        options.avoidRecursion = yes
        return do defaultCallback

      appParams = options.params or {}

      if appOptions?.multiple
        { forceNew, showInstance = yes } = options
        if forceNew or appOptions.openWith is 'forceNew'
          return @create name, appParams, (appInstance) =>
            if showInstance
            then @showInstance appInstance, callback
            else kd.utils.defer -> callback appInstance

        switch appOptions.openWith
          when 'lastActive' then do defaultCallback
          when 'prompt'     then do defaultCallback

      else do defaultCallback


  openFileWithApplication: (appName, file) ->
    @open appName, => kd.utils.defer => @getFrontApp().openFile file


  promptOpenFileWith: (file) ->
    finderController = kd.getSingleton 'finderController'
    { treeController } = finderController
    view = new KDView {}, file
    treeController.showOpenWithModal view


  openFile: (file) ->

    extension  = file.getExtension()
    type       = FSHelper.getFileType extension
    defaultApp = @defaultApps[extension]

    return @openFileWithApplication defaultApp, file  if defaultApp

    switch type
      when 'unknown'
        @promptOpenFileWith file
      when 'code', 'text'
        kd.log 'open with a text editor'
        @open @defaultApps.text, (appController) -> appController.openFile file
      when 'image'
        kd.log 'open with an image processing app'
      when 'video'
        kd.log 'open with a video app'
      when 'sound'
        kd.log 'open with a sound app'
      when 'archive'
        kd.log 'extract the thing.'


  tell: (name, command, rest...) ->

    return kd.warn 'ApplicationManager::tell called without an app name!'  unless name

    app = @get name
    cb  = (appInstance) -> appInstance?[command]? rest...

    if app then kd.utils.defer -> cb app
    else @create name, cb


  require: (name, params, callback) ->

    [callback, params] = [params, callback]  unless callback
    callback ?= kd.noop

    if app = @get name
    then callback app
    else @create name, params, callback


  create: (name, params, callback) ->

    [callback, params] = [params, callback]  unless callback

    AppClass              = getAppClass name
    appOptions            = $.extend {}, true, getAppOptions name
    appOptions.params     = params

    @register appInstance = new AppClass appOptions  if AppClass

    if @shouldLoadApp name
      return KodingAppsController.loadInternalApp name, (err) =>
        return kd.warn err  if err
        kd.utils.defer => @create name, params, callback

    kd.utils.defer =>
      return @emit 'AppCouldntBeCreated'  unless appInstance
      @emit 'AppCreated', appInstance

      if appOptions.thirdParty
        return kd.getSingleton('kodingAppsController').putAppResources appInstance, callback

      callback? appInstance


  show: (name, appParams, callback) ->

    appOptions  = getAppOptions name
    appInstance = @get name

    return if appOptions.background

    appView     = appInstance.getView?()
    return unless appView

    @emit 'AppIsBeingShown', appInstance, appView, appOptions
    appInstance.appIsShown? appParams

    @setLastActiveIndex appInstance
    kd.utils.defer -> callback? appInstance


  showInstance: (appInstance, callback) ->

    appView    = appInstance.getView?() or null
    appOptions = getAppOptions appInstance.getOption 'name'

    return if appOptions.background

    @emit 'AppIsBeingShown', appInstance, appView, appOptions
    appInstance.appIsShown?()
    @setLastActiveIndex appInstance
    kd.utils.defer -> callback? appInstance


  quit: (appInstance, callback = kd.noop) ->
    view = appInstance.getView?()
    destroyer = if view? then view else appInstance
    appInstance.beforeQuit?()
    destroyer.destroy()
    callback()

  quitAll: ->

    for own name, apps of @appControllers
      @quit app  for app in apps.instances


  quitByName: (name, callback = kd.noop) ->

    appController = @appControllers[name]
    return callback null  unless appController

    instances = appController.instances
    queue     = instances.map (instance) =>
      (next) => @quit instance, next

    async.series queue, callback


  get: (name) ->

    if apps = @appControllers[name]
      apps.instances[apps.lastActiveIndex] or apps.instances.first
    else
      null


  getByView: (view) ->

    appInstance = null
    for own name, apps of @appControllers
      for appController in apps.instances
        if view.getId() is appController.getView?()?.getId()
          appInstance = appController
          break
      break if appInstance

    return appInstance


  getFrontApp: -> @frontApp


  setFrontApp: (appInstance) ->

    { router } = kd.singletons
    { name }   = appInstance.getOptions()

    router.setPageTitle name  if name

    @setLastActiveIndex appInstance

    prevAppInstance = @frontApp
    @frontApp = appInstance

    @emit 'FrontAppIsChanged', appInstance, prevAppInstance


  getFrontAppManifest: ->
    { name }  = @getFrontApp().getOptions()
    return getAppOptions name


  register: (appInstance) ->

    name = appInstance.getOption 'name'
    @appControllers[name] ?=
      instances       : []
      lastActiveIndex : null

    @appControllers[name].instances.push appInstance
    @setListeners appInstance

    @emit 'AppRegistered', name, appInstance.options


  unregister: (appInstance) ->

    name  = appInstance.getOption 'name'
    app   = @appControllers[name]

    return no  unless app

    index = app.instances.indexOf appInstance

    return  no  unless index >= 0

    @appControllers[name].instances.splice index, 1

    @emit 'AppUnregistered', name, appInstance.options

    if @appControllers[name].instances.length is 0
      delete @appControllers[name]


  createPromptModal: (appOptions, callback) ->
    # show modal and wait for response
    { name } = appOptions
    selectOptions = for instance, i in @appControllers[name].instances
      title : "#{instance.getOption('name')} (#{i+1})"
      value : i

    modal = new KDModalViewWithForms
      title                 : 'Open with:'
      tabs                  :
        navigable           : no
        forms               :
          openWith          :
            callback        : (formOutput) ->
              modal.destroy()
              { index, openNew } = formOutput
              callback index, openNew
            fields          :
              instance      : {
                label       : 'Instance:'
                itemClass   : KDSelectBox
                name        : 'index'
                type        : 'select'
                defaultValue: selectOptions.first.value
                selectOptions
              }
              newOne        :
                label       : 'Open new app:'
                itemClass   : KDOnOffSwitch
                name        : 'openNew'
                defaultValue: no
            buttons         :
              Open          :
                cssClass    : 'solid green medium'
                type        : 'submit'
              Cancel        :
                cssClass    : 'solid light-gray medium'
                callback    : ->
                  modal.cancel()
                  callback null


  setListeners: (appInstance) ->

    destroyer = if view = appInstance.getView?() then view else appInstance
    destroyer.once 'KDObjectWillBeDestroyed', =>
      @unregister appInstance
      appInstance.emit 'AppDidQuit'
      kd.getSingleton('appManager').emit  'AppDidQuit', appInstance


  setLastActiveIndex: (appInstance) ->

    return unless appInstance

    if optionSet = @appControllers[appInstance.getOption 'name']
      index = optionSet.instances.indexOf appInstance
      if index is -1 then optionSet.lastActiveIndex = null
      else optionSet.lastActiveIndex = index


  # setGroup: -> console.log 'setGroup', arguments


  # temp
  notification = null


  notify: (msg) ->

    notification.destroy() if notification

    notification = new KDNotificationView
      title     : msg or 'Currently disabled!'
      type      : 'mini'
      duration  : 2500


  handleAppNotFound: ->
    new KDNotificationView
      title    : "You don't have this app installed!"
      type     : 'mini'
      cssClass : 'error'
      duration : 5000


  getInstance: (app, key, value) ->

    if not appController = kd.singletons.appManager.appControllers[app]
      return null

    for instance in appController.instances
      return instance  if instance and instance[key] is value

    return null
