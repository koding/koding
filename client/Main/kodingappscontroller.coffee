class KodingAppsController extends KDController

  name    = "KodingAppsController"
  version = "0.1"

  KD.registerAppClass this, {name, version, background: yes}

  constructor:->
    super

    appStorage = KD.getSingleton 'appStorageController'
    @storage   = appStorage.storage "Applications", version

    @storage.fetchStorage (storage)=>
      @apps = @storage.getValue('installed') or {}
      @apps or= {}

      @emit 'ready'

  @loadInternalApp = (name, callback)->

    unless KD.config.apps[name]
      warn message = "#{name} is not available to run!"
      return callback {message}

    if name.capitalize() in Object.keys KD.appClasses
      warn "#{name} is already imported"
      return callback null

    KD.singletons.dock.setNavItemState {name, route:"/#{name}" }, 'loading'

    app = KD.config.apps[name]
    @putAppScript app, callback

  # This is the most important method to put & run additional apps on Koding
  # Please make sure about your changes on it.
  @putAppScript = (app, callback = noop)->

    if app.style
      @appendScriptElement 'style',  \
        { url:app.style, identifier:app.identifier, callback }, yes

    if app.script
      @appendScriptElement 'script', \
        { url:app.script, identifier:app.identifier, callback }, yes

  @unloadAppScript = (app, callback = noop)->

    identifier = app.identifier.replace /\./g, '_'

    @destroyScriptElement "style", identifier
    @destroyScriptElement "script", identifier

    KD.utils.defer -> callback()

  @runApprovedApp = (jApp, options = {}, callback = noop)->

    return warn "JNewApp not found!"  unless jApp

    {script, style} = jApp.urls
    return warn "Script not found! on #{jApp}"  unless script

    app = {
      name : jApp.name
      script, style
      identifier : jApp.identifier
    }

    if jApp.approved
      route = "/#{jApp.name}"
    else
      route = "/Apps/#{jApp.manifest.authorNick}/#{jApp.name}/run"

    @putAppScript app, ->

      KD.utils.defer ->

        if options.dontUseRouter
          KD.singletons.appManager.open jApp.name
        else
          KD.singletons.router.handleRoute route

        callback()

  @runExternalApp = (jApp, options = {}, callback = noop)->

    if jApp.approved or jApp.manifest.authorNick is KD.nick()
      return @runApprovedApp jApp, options

    modal = new KDModalView
      title          : "Run #{jApp.manifest.name}"
      content        : """This is <strong>DANGEROUS!!!</strong>
                          If you don't know this user, its recommended to not run this app!
                          Do you still want to continue?"""
      height         : "auto"
      overlay        : yes
      buttons        :
        Run          :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : => @runApprovedApp jApp, options, -> modal.destroy()

        cancel       :
          style      : "modal-cancel"
          callback   : -> modal.destroy()

  @appendScriptElement = (type, {identifier, url, callback}, force)->

    identifier = identifier.replace /\./g, '_'
    domId      = "internal-#{type}-#{identifier}"
    vmName     = FSHelper.getVMNameFromPath url
    tagName    = type

    # Which means this is an invm-app
    if vmName

      file = FSHelper.createFileFromPath url
      file.fetchContents (err, partial)=>
        return  if err
        obj = new KDCustomHTMLView {domId, tagName, partial}

        @destroyScriptElement type, identifier  if force

        if type is 'script'
          obj.once 'viewAppended', -> callback null

        KD.utils.defer -> obj.appendToSelector 'head'

    else

      url  = "#{url}?#{KD.utils.uniqueId()}"
      bind = ''
      load = noop

      if type is 'style'
        tagName    = 'link'
        attributes =
          rel      : 'stylesheet'
          href     : url
      else
        attributes =
          type     : "text/javascript"
          src      : url
        bind       = "load"
        load       = -> callback? null

      @destroyScriptElement type, identifier  if force

      document.head.appendChild (new KDCustomHTMLView {
        domId, tagName, attributes, bind, load
      }).getElement()

  @destroyScriptElement = (type, identifier)->
    (document.getElementById "internal-#{type}-#{identifier}")?.remove()

  # #
  # MAKE NEW APP
  # #

  defaultManifest = (type, name)->
    {profile} = KD.whoami()
    fullName  = KD.utils.getFullnameFromAccount()
    raw =
      devMode       : yes
      experimental  : no
      multiple      : no
      background    : no
      hiddenHandle  : no
      forceUpdate   : no
      openWith      : "lastActive"
      behavior      : "application"
      version       : "0.1"
      title         : "#{name or type.capitalize()}"
      name          : "#{name or type.capitalize()}"
      identifier    : "com.koding.apps.#{__utils.slugify name or type}"
      path          : "~/Applications/#{name or type.capitalize()}.kdapp"
      homepage      : "#{profile.nickname}.#{KD.config.userSitesDomain}/#{__utils.slugify name or type}"
      author        : "#{fullName}"
      authorNick    : "#{profile.nickname}"
      repository    : "git://github.com/#{profile.nickname}/#{__utils.slugify name or type}.kdapp.git"
      description   : "#{name or type} : a Koding application created with the #{type} template."
      category      : "web-app" # can be web-app, add-on, server-stack, framework, misc
      source        :
        blocks      :
          app       :
            # pre     : ""
            files   : [ "./index.coffee" ]
            # post    : ""
        stylesheets : [ "./resources/style.css" ]
      options       :
        type        : "tab"
      icns          :
        "128"       : "./resources/icon.128.png"
      screenshots   : []
      menu          : []
      fileTypes     : []

    json = JSON.stringify raw, null, 2

  newAppModal = null

  getAppPath:(manifest, escaped=no)->

    path = if 'string' is typeof manifest then manifest else manifest.path
    path = if /^~/.test path then "/home/#{KD.nick()}#{path.substr(1)}"\
           else path
    return FSHelper.escapeFilePath path  if escaped
    return path.replace /(\/+)$/, ""

  makeNewApp:(callback)->

    return callback? yes if newAppModal

    newAppModal = new KDModalViewWithForms
      title                       : "Create a new Application"
      content                     :
        """
          <div class='modalformline'>
            <p>
              Please provide a name for your awesome Koding App you want to start with.
            </p>
          </div>
        """
      overlay                     : yes
      width                       : 600
      height                      : "auto"
      tabs                        :
        navigable                 : yes
        forms                     :
          form                    :
            buttons               :
              Create              :
                cssClass          : "modal-clean-gray"
                loader            :
                  color           : "#444444"
                  diameter        : 12
                callback          : =>
                  form = newAppModal.modalTabs.forms.form
                  unless form.inputs.name.validate()
                    form.buttons.Create.hideLoader()
                    return
                  name        = form.inputs.name.getValue()
                  unless name
                    return new KDNotificationView
                      title : "Application name is not provided."

                  type        = "blank"
                  name        = (name.replace /[^a-zA-Z]/g, '').capitalize()
                  manifestStr = defaultManifest type, name
                  manifest    = JSON.parse manifestStr
                  appPath     = @getAppPath manifest
                  defaultVm   = KD.singletons.vmController.defaultVmName

                  FSHelper.exists appPath, defaultVm, (err, exists)=>
                    if exists
                      form.buttons.Create.hideLoader()
                      new KDNotificationView
                        type      : "mini"
                        cssClass  : "error"
                        title     : "App folder with that name is already exists, please choose a new name."
                        duration  : 3000
                    else
                      @prepareApplication name, (err, response)=>
                        callback? err
                        form.buttons.Create.hideLoader()
                        newAppModal.destroy()

            fields                :
              name                :
                label             : "Name:"
                name              : "name"
                placeholder       : "name your application..."
                validate          :
                  rules           :
                    regExp        : /^[a-z]+([a-z]+)*$/i
                  messages        :
                    regExp        : "For Application name only lowercase letters are allowed!"

    newAppModal.once "KDObjectWillBeDestroyed", ->
      newAppModal = null
      callback? yes

  _createChangeLog:(name)->
    today = new Date().format('yyyy-mm-dd')
    {profile} = KD.whoami()
    fullName  = KD.utils.getFullnameFromAccount()

    """
     #{today} #{fullName} <@#{profile.nickname}>

        * #{name} (index.coffee): Application created.
    """

  prepareApplication:(name, callback)->

    unless name
      return new KDNotificationView
        title : "Application name is not provided."

    type         = "blank"
    appname      = KD.utils.slugify name.replace /[^a-zA-Z]/g, ''
    APPNAME      = appname.capitalize()
    manifestStr  = defaultManifest type, APPNAME
    changeLogStr = @_createChangeLog APPNAME
    manifest     = JSON.parse manifestStr
    appPath      = @getAppPath manifest

    {vmController} = KD.singletons

    stack = [

      (cb)->

        vmController.run
          method    : "app.skeleton"
          withArgs  :
            type    : "blank"
            appPath : appPath
          , cb

      (cb)->

        indexFile = FSHelper.createFileFromPath "#{appPath}/index.coffee"
        indexFile.fetchContents (err, content)->
          return cb err  if err
          content = content.replace(/\%\%APPNAME\%\%/g, APPNAME)
                           .replace(/\%\%appname\%\%/g, appname)
                           .replace(/\%\%AUTHOR\%\%/g , KD.nick())
          indexFile.save content, cb

      (cb)->

        styleFile = FSHelper.createFileFromPath "#{appPath}/resources/style.css"
        styleFile.fetchContents (err, content)->
          return cb err  if err
          content = content.replace(/\%\%appname\%\%/g, appname)
          styleFile.save content, cb

      (cb)->

        FSHelper.createFileFromPath("#{appPath}/manifest.json")
                .save manifestStr,  cb

      (cb)->

        FSHelper.createFileFromPath("#{appPath}/ChangeLog")
                .save changeLogStr, cb

    ]

    async.series stack, (err, result) =>
      warn err  if err
      callback? err, result

  ###

  @manifests = {}

  @getManifestFromPath = getManifestFromPath = (path)->
    folderName = (p for p in path.split("/") when /\.kdapp/.test p)[0]
    app        = null
    return app unless folderName
    for own name, manifest of KodingAppsController.manifests
      do -> app = manifest  if manifest.path.search(folderName) > -1
    return app

  constructor:->

    super

    @_loadedOnce    = no
    @appManager     = KD.getSingleton "appManager"
    @vmController   = KD.getSingleton "vmController"
    mainController  = KD.getSingleton "mainController"
    @manifests      = KodingAppsController.manifests
    @publishedApps  = {}
    @_fetchQueue    = []
    @appStorage     = KD.getSingleton('appStorageController').storage 'Finder', '1.1.1'
    @watcher        = new AppsWatcher

    # @fetchApps =>
    #   @getPublishedApps()
    #   @createExtensionToAppMap()
    #   @fetchUserDefaultAppConfig()

    @on "UpdateDefaultAppConfig", (extension, appName) =>
      @updateDefaultAppConfig extension, appName

    mainController.on "accountChanged.to.loggedIn", @bound "getPublishedApps"

    #  - NewAppIsAdded
    #  - FileIsRemoved
    #  - AppIsRemoved
    #  - FileHasChanged
    #  - ManifestHasChanged

    @watcher.on "NewAppIsAdded", (app, change)=>
      manifestPath = "#{change.file.fullPath}/manifest.json"
      manifest = FSHelper.createFileFromPath manifestPath
      manifest.exists (err, exists)=>
        return  unless exists
        @fetchAppFromFs app, =>
          @putAppsToAppStorage null, =>
            @emit "UpdateAppData", app

    @watcher.on "AppIsRemoved", (app, change)=>
      @invalidateDeletedApps [app], no, =>
        @emit "InvalidateApp", app

    @watcher.on "ManifestHasChanged", (app, change)=>
      @fetchAppFromFs app, =>
        @putAppsToAppStorage null, =>
          @emit "UpdateAppData", app

  # #
  # FETCHERS
  # #

  fetchApps:(callback)->

    kb = (manifests)=>
      callback null, manifests
      @watcher._trackedApps = if manifests then Object.keys manifests else []

    @appStorage.ready =>
      manifests = @getManifests()
      apps      = Object.keys manifests
      if apps.length > 0 then kb manifests
      else
        @fetchAppsFromDb (err, apps)=>
          if err
            @fetchAppsFromFs (err, apps)=>
              return callback? err  if err
              kb apps
          else if err
            callback? err
          else
            kb apps

  fetchAppFromFs:(appName, cb)->

    manifests = @getManifests()
    appsPath = "/home/#{KD.nick()}/Applications/"
    suffix   = ".kdapp/manifest.json"

    manifest = FSHelper.createFileFromPath "#{appsPath}#{appName}#{suffix}"
    manifest.fetchContents (err, response)=>
      # warn err  if err
      return cb null  if err or not response

      try
        manifest = JSON.parse response
        manifests[manifest.name] = manifest
      catch e
        warn "Manifest file is broken:", e
        return cb null

      @constructor.manifests = manifests
      cb null

  fetchAppsFromFsHelper:(apps, callback)->

    stack = []
    apps.forEach (app)=>
      stack.push (cb)=> @fetchAppFromFs app, cb
    async.parallel stack, callback

  fetchAppsFromFs:(cb)->

    @_fetchQueue.push cb  if cb
    return if @_fetchQueue.length > 1

    @watcher.watch KD.utils.getTimedOutCallback (err, files)=>
      @_loadedOnce = yes
      if err or not Array.isArray files or files.length is 0
        @putAppsToAppStorage {}
        callback()  for callback in @_fetchQueue
        @_fetchQueue = []
      else
        apps = @filterAppsFromFileList files
        @fetchAppsFromFsHelper apps, (result)=>
          @putAppsToAppStorage()
          for callback in @_fetchQueue
            callback null, @getManifests()
          @_fetchQueue = []
    , =>
      warn msg = "Timeout reached for kite request"
      KD.logToExternalWithTime msg
      callback() for callback in @_fetchQueue
      @_fetchQueue = []
    , KD.config.fileFetchTimeout

  fetchAppsFromDb:(callback)->

    @appStorage.fetchValue 'apps', (apps)=>
      @putDefaultShortcutsBack =>
        if apps and Object.keys(apps).length > 0
          @constructor.manifests = apps
          callback null, apps
        else
          callback new Error "There are no apps in the app storage."

  syncAppStorageWithFS:(force=no, callback=noop)->

    currentApps = Object.keys(@getManifests())

    # log "Synchronizing AppStorage with FileSystem..."

    @watcher.watch (err, files)=>

      return warn err  if err

      existingApps = @filterAppsFromFileList files
      newApps      = (app for app in existingApps when app not in currentApps) or []
      removedApps  = (app for app in currentApps  when app not in existingApps) or []

      # log "APPS FOUND IN AppStorage:", currentApps
      # log "APPS FOUND IN FS:", existingApps
      # log "REMOVED APPS:", removedApps
      # log "NEW APPS:", newApps

      # log "Nothing changed"  if removedApps.length is 0 and \
      #                           newApps.length is 0

      @invalidateDeletedApps removedApps, force, =>
        # log "DELETED APPS REMOVED FROM APPSTORAGE"
        appsToFetch = if force then existingApps else newApps
        # log "FOLLOWING APPS WILL BE FETCHED", appsToFetch
        @fetchAppsFromFsHelper appsToFetch, =>
          # log "APPS FETCHED"
          @emit "AppsDataChanged", {removedApps, newApps, existingApps, force}

      @_loadedOnce = yes
      callback?()

  filterAppsFromFileList:(files)->
    return (file.name.replace /\.kdapp$/, '' \
            for file in files when (/\.kdapp$/.test file.name) \
            and file.type is 'folder')

  fetchUpdateAvailableApps: (callback, force) ->
    return callback? null, @updateAvailableApps  if @updateAvailableApps and not force
    {publishedApps}      = @
    @updateAvailableApps = []

    @fetchApps (err, apps) =>
      for own appName, app of apps
        if @isAppUpdateAvailable app.name, app.version
          @updateAvailableApps.push publishedApps[app.name]
      callback? null, @updateAvailableApps

  fetchCompiledAppSource:(manifest, callback)->

    indexJs = FSHelper.createFileFromPath "#{@getAppPath manifest}/index.js"
    indexJs.fetchContents callback

  # #
  # MISC
  # #

  removeShortcut:(shortcut, callback)->
    @appStorage.fetchValue 'shortcuts', (shortcuts)=>
      delete shortcuts[shortcut]
      @appStorage.setValue 'shortcuts', shortcuts, (err)->
        callback err

  putDefaultShortcutsBack:(callback)->
    # if @appStorage.getValue 'shortcuts'
    #   return  @utils.defer -> callback null

    # @appStorage.reset()
    @appStorage.setValue 'shortcuts', defaultShortcuts, (err)->
      callback? err

  putAppsToAppStorage:(apps, callback)->
    # warn "calling putAppsToAppStorage:", apps
    apps or= @getManifests()
    @constructor.manifests = apps
    @appStorage.setValue 'apps', apps, (err)-> callback? err

  invalidateDeletedApps:(deletedApps, force=no, callback)->
    # log "REQUESTED TO INVALIDATE:", deletedApps
    return if force
      @constructor.manifests = {}
      @putAppsToAppStorage manifests, callback

    manifests = @getManifests()
    delete manifests[app]  for app in deletedApps
    if deletedApps.length > 0
      @putAppsToAppStorage manifests, callback
    else
      callback null

  defineApp:(name, script)->
    KD.registerAppScript name, script if script

  getAppScript:(manifest, callback = noop)->

    {name} = manifest

    if script = KD.getAppScript name
      callback null, script
    else
      @fetchCompiledAppSource manifest, (err, script)=>
        if err
          @compileApp name, callback
        else
          @defineApp name, script
          callback err, script

  getPublishedApps: (callback) ->
    # return unless KD.isLoggedIn()
    appNames = (appName for own appName, manifest of @getManifests()) or []
    query    = "manifest.name": "$in": appNames
    {JNewApp}   = KD.remote.api
    JNewApp.fetchAllAppsData query, (err, apps)=>
      @publishedApps = map = {}
      apps?.forEach (app) =>
        map[app.manifest.name] = new JNewApp app
      @emit "UserAppModelsFetched", map
      callback? map

  isAppUpdateAvailable: (appName, appVersion) ->
    if @publishedApps[appName]
      return @utils.versionCompare appVersion, "lt", @publishedApps[appName].manifest.version

  getAppUpdateType: (appName) ->
    app = @publishedApps[appName]
    return null unless app
    return if app.manifest.forceUpdate is yes then "required" else "available"

  updateAllApps:->
    @fetchUpdateAvailableApps (err, apps) =>
      return warn err  if err
      stack = []
      delete @notification
      apps?.forEach (app) =>
        stack.push (callback) =>
          @updateUserApp app.manifest, callback
      async.series stack

  # added this to keep backward compatibility
  refreshApps: (callback) -> @syncAppStorageWithFS yes, callback

  updateUserApp:(manifest, callback)->
    appName = manifest.name
    unless @notification
      @notification = new KDNotificationView
        type        : "mini"
        title       : "Updating #{appName}: Deleting old app files"
        duration    : 10000

    folder = FSHelper.createFileFromPath manifest.path, "folder"
    folder.remove (err, res) =>
      if err
        @notification.setClass "error"
        @notification.notificationSetTitle "An error occured while updating #{appName}."
        return no
      @refreshApps =>
        @notification.notificationSetTitle "Updating #{appName}: Fetching new app details"
        KD.remote.api.JNewApp.someWithRelationship { "manifest.name": appName }, {}, (err, app) =>
          @notification.notificationSetTitle "Updating #{appName}: Updating app to latest version"
          @installApp app[0], app[0].versions.last, =>
            @refreshApps()
            callback?()
            @emit "AnAppHasBeenUpdated"
            @notification.notificationSetTitle "#{appName} has been updated successfully"
      , yes

  # #
  # KITE INTERACTIONS
  # #

  hasForceUpdate: (appInstance) ->
    manifest                 = @constructor.manifests[appInstance.getOptions().name]
    {devMode, name, version} = manifest
    forceUpdate              = @getAppUpdateType(name) is "required"
    updateAvailable          = @isAppUpdateAvailable(name, version)
    hasUpdate                = updateAvailable and not devMode and forceUpdate

    @showUpdateRequiredModal manifest  if hasUpdate
    return hasUpdate

  putAppResources: (appInstance) ->
    return  unless appInstance

    manifest = appInstance.getOptions()
    return  unless manifest.thirdParty

    appView = appInstance.getView()
    appView.addSubView loader = new KDLoaderView
      loaderOptions :
        color       : "#ff9200"
        speed       : 2
        range       : 0.7
        density     : 60
      cssClass      : "app-loading"
      size          :
        width       : 128

    appView.once "viewAppended", -> loader.show()

    putStyleSheets manifest

    @getAppScript manifest, (err, appScript)=>
      return warn err  if err

      loader.destroy()
      id = appView.getId()

      try
        # security please!
        do (appView)->
          eval "var appView = KD.instances[\"#{id}\"];\n\n" + appScript
      catch error
        # if not manifest.ignoreWarnings? # GG FIXME
        showError error


  publishApp:(path, callback)->

    if not (KD.checkFlag('app-publisher') or KD.checkFlag('super-admin'))
      err = "You are not authorized to publish apps."
      log err
      callback? err
      return no

    manifest = getManifestFromPath(path)
    appName  = manifest.name

    notification = new KDNotificationView
      overlay       :
        transparent : no
        destroyOnClick: no
      loader        :
        color       : "#ffffff"
      title         : "Please wait while we are publishing your app..."
      followUps     :
        duration    : 10000
        title       : "We are still working on it. Your app will be published soon..."
      duration      : 120000

    @getAppScript manifest, (appScript)=>

      manifest   = @getManifest appName
      appPath    = @getAppPath manifest
      options    =
        method   : "app.publish"
        withArgs : {appPath}

      @vmController.run options, (err, res)=>
        if err
          warn err
          notification.destroy()
          callback? err
        else
          manifest.authorNick = KD.whoami().profile.nickname
          jAppData     =
            title      : manifest.name        or "Application Title"
            body       : manifest.description or "Application description"
            identifier : manifest.identifier  or "com.koding.apps.#{__utils.slugify manifest.name}"
            manifest   : manifest

          notification.destroy()

          @createApp jAppData, (err, app) =>
            if err
              warn err
              return callback? err
            @appManager.open "Apps"
            @appManager.tell "Apps", "updateApps"
            callback?()

  createApp:(formData, callback)->
    KD.remote.api.JNewApp.create formData, (err, app)->
      callback? err, app

  compileApp:(name, callback)->

    compileOnServer = (app)=>
      return warn "#{name}: No such application!" unless app
      appPath = @getAppPath app

      loader = new KDNotificationView
        duration : 18000
        title    : "Compiling #{name}..."
        type     : "mini"

      @vmController.run "kdc #{appPath}", (err, response)=>
        if not err
          nickname    = KD.nick()
          publishPath = "/home/#{nickname}/Web/.applications"
          @vmController.run
            method      : "fs.createDirectory"
            withArgs    :
              path      : publishPath
              recursive : yes
          , (err, response)=>
            loader.notificationSetTitle "Publishing app static files..."
            linkFile = "#{publishPath}/#{KD.utils.slugify name}"
            @vmController.run "rm #{linkFile}; ln -s #{appPath} #{linkFile}", (err, response)=>
              loader.notificationSetTitle "Fetching compiled app..."
              @fetchCompiledAppSource app, (err, res)=>
                if not err
                  @defineApp name, res
                  loader.notificationSetTitle "App compiled successfully"
                  loader.notificationSetTimer 2000
                callback? err, res
        else
          loader.destroy()

          if err.message is "exit status 127"
            modal = new ModalViewWithTerminal
              title   : "Koding app compiler is not installed in your VM."
              width   : 500
              overlay : yes
              terminal:
                hidden: yes
              content : """
                        <div class='modalformline'>
                          <p>
                            If you want to install it now, click <strong>Install Compiler</strong> button.
                          </p>
                          <p>
                            <strong>Remember to enter your password when asked.</strong>
                          </p>
                        </div>
                        """
              buttons:
                "Install Compiler":
                  cssClass: "modal-clean-green"
                  callback: =>
                    modal.run "sudo npm install -g kdc; echo $?|kdevent;" # find a clean/better way to do it.

            modal.on "terminal.event", (data)->
              if data is "0"
                new KDNotificationView title: "Installed successfully!"
                modal.destroy()
              else
                new KDNotificationView
                  title   : "An error occured."
                  content : "Something went wrong while installing Koding App Compiler. Please try again."

            callback? err
            return

          if response
            details = """<pre>#{response}</pre>"""
          else
            details = ""

          new KDModalView
            title   : "An error occured while compiling the App!"
            width   : 500
            overlay : yes
            content : """
                      <div class='modalformline'>
                        <p>#{err.message}</p>
                        #{details}
                      </div>
                      """
          callback? err

    unless @getManifest name
      @fetchApps (err, apps)->
        compileOnServer apps[name]
    else
      compileOnServer @getManifest name

  getManifests:->
    @constructor.manifests

  getManifest:(appName)->
    @constructor.manifests[appName]

  installApp:(app, version, callback)->

    # add group membership control when group based apps feature is implemented!
    KD.requireMembership
      onFailMsg : "Login required to install Apps"
      onFail    : => callback yes
      callback  : => @fetchApps (err, manifests = {})=>

        KD.showError err,
          KodingError : 'Something went wrong while fetching apps'
        return callback? err  if err

        if app.title in Object.keys(manifests)
          new KDNotificationView
            type : "mini", title : "App is already installed!"
          callback? yes
        else
          if app.approved isnt yes and not KD.checkFlag 'app-publisher'
            KD.showError "This app is not approved, installation cancelled."
            callback? err
          else
            app.fetchCreator (err, acc)=>
              KD.showError err,
                KodingError : 'Failed to fetch app creator info'
              return callback? err  if err

              KD.mixpanel "Install Application, success", app.manifest.identifier

              @vmController.run
                method       : "app.install"
                withArgs     :
                  owner      : acc.profile.nickname
                  identifier : app.manifest.identifier
                  appPath    : @getAppPath app.manifest
                  version    : version
              , (err, res)=>
                if err
                  KD.showError err,
                    KodingError: """Something wrong with Apps server,
                                    please try again later"""
                  return callback?()
                app.install (err)=>
                  KD.showError err
                  @appManager.open "StartTab"
                  callback?()

  # #
  # FORK / CLONE APP
  # #

  downloadAppSource:(path, callback)->

    @fetchApps =>
      manifest = getManifestFromPath path

      unless manifest
        callback new KDNotificationView type : "mini", title : "Please refresh your apps and try again!"
        return

      @vmController.run
        method       : "app.download"
        withArgs     :
          owner      : manifest.authorNick
          identifier : manifest.identifier
          appPath    : @getAppPath manifest
          version    : manifest.version
      , (err, res)=>
        if err
          warn err
          callback? err
        else
          callback? null

  # #
  # HELPERS
  # #

  putStyleSheets = (manifest)->
    {name, devMode, version, identifier} = manifest
    {stylesheets} = manifest.source if manifest.source

    return unless stylesheets

    $("head .app-#{__utils.slugify name}").remove()
    stylesheets.forEach (sheet)->
      if devMode
        urlToStyle = "https://#{KD.nick()}.#{KD.config.userSitesDomain}/.applications/#{__utils.slugify name}/#{__utils.stripTags sheet}?#{Date.now()}"
        $('head').append "<link class='app-#{__utils.slugify name}' rel='stylesheet' href='#{urlToStyle}'>"
      else
        if /(http)|(:\/\/)/.test sheet
          warn "external sheets cannot be used"
        else
          sheet = sheet.replace /(^\.\/)|(^\/+)/, ""
          $('head').append("<link class='app-#{__utils.slugify name}' rel='stylesheet' href='#{KD.appsUri}/#{manifest.authorNick or KD.nick()}/#{__utils.stripTags identifier}/#{__utils.stripTags version}/#{__utils.stripTags sheet}'>")

  showError = (error)->
    new KDModalView
      title   : "An error occured while running the App!"
      width   : 500
      overlay : yes
      content : """
                <div class='modalformline'>
                  <h3>#{error.constructor.name}</h3><br/>
                  <pre>#{error.message}</pre>
                </div>
                <p class='modalformline'>
                  <cite>Check Console for more details.</cite>
                </p>
                """
                # We may after put a full stck to the output
                # It looks weird for now.
                # <pre>#{error.stack}</pre>

    console.warn error.message, error

  showUpdateRequiredModal: (manifest) ->
    {name} = manifest
    modal  = new KDModalView
      title          : "Update Required for #{name}"
      content        : """
        <div class="app-update-modal">
          <p>Author of #{name} made this update required. You must update to keep on using the app.</p>
          <p><span class="app-update-warning">Warning:</span> Updating an app will delete it's current folder to install new version. This cannot be undone. If you have updated files, back up them now.</p>
        </div>
      """
      overlay        : yes
      buttons        :
        Update       :
          style      : "modal-clean-green"
          loader     :
            color    : "#FFFFFF"
            diameter : 12
          callback   : =>
            @updateUserApp manifest, ->
              modal.buttons.Update.hideLoader()
              modal.destroy()
        "Close" :
          style      : "modal-cancel"
          callback   : => modal.destroy()

  createExtensionToAppMap: ->
    @extensionToApp = map = {}

    for own key, app of @getManifests()
      fileTypes = app.fileTypes
      continue  unless fileTypes
      for type in fileTypes
        map[type] or= []
        map[type].push app.name

    # Still there should be a more elagant way to add ace file types into map.
    for type in KD.getAppOptions("Ace").fileTypes
      map[type] or= []
      map[type].push "Ace"

  fetchUserDefaultAppConfig: ->
    @appConfigStorage = new AppStorage "DefaultAppConfig", "1.0"
    @appConfigStorage.fetchStorage (storage) =>
      settings = @appConfigStorage.getValue "settings"
      for own extension, appName of settings
        @appManager.defaultApps[extension] = appName

  updateDefaultAppConfig: (extension, appName) ->
    {defaultApps} = @appManager
    defaultApps[extension] = appName
    @appConfigStorage.setValue "settings", defaultApps

  defaultShortcuts =
    Ace           :
      name        : 'Ace'
      type        : 'koding-app'
      icon        : 'icn-ace.png'
      description : 'Code Editor'
      author      : 'Mozilla'
      route       : '/Develop/Ace'
    Terminal      :
      name        : 'Terminal'
      type        : 'koding-app'
      icon        : 'icn-terminal.png'
      description : 'Koding Terminal'
      author      : 'Koding'
      route       : '/Develop/Terminal'
    Teamwork      :
      name        : 'Teamwork'
      type        : 'koding-app'
      icon        : 'teamwork/icon.256.png'
      description : 'Koding\'s official collaboration app'
      author      : 'Koding'
      route       : '/Develop/Teamwork'

  ###
