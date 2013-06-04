class KodingAppsController extends KDController

  KD.registerAppClass this,
    name       : "KodingAppsController"
    background : yes

  @manifests = {}

  @getManifestFromPath = getManifestFromPath = (path)->

    folderName = (p for p in path.split("/") when /\.kdapp/.test p)[0]
    app        = null

    return app unless folderName

    for own name, manifest of KodingAppsController.manifests
      do ->
        app = manifest if manifest.path.search(folderName) > -1

    return app

  constructor:->

    super

    @appManager     = @getSingleton "appManager"
    @kiteController = @getSingleton "kiteController"
    @manifests      = KodingAppsController.manifests
    @getPublishedApps()

  getAppPath:(manifest, escaped=no)->

    {profile} = KD.whoami()
    path = if 'string' is typeof manifest then manifest else manifest.path
    path = if /^~/.test path then "/home/#{profile.nickname}#{path.substr(1)}"\
           else path
    return FSHelper.escapeFilePath path  if escaped
    return path.replace /(\/+)$/, ""

  # #
  # FETCHERS
  # #

  fetchApps:(callback)->

    if KD.isLoggedIn() and not @appStorage?
      @appStorage = new AppStorage 'KodingApps', '1.0'

    if Object.keys(@constructor.manifests).length isnt 0
      callback null, @constructor.manifests
    else
      @fetchAppsFromDb (err, apps)=>
        if err
          @fetchAppsFromFs (err, apps)=>
            if err then callback()
            else callback null, apps
        else
          callback? err, apps

  fetchAppsFromFs:(callback)->

    path   = "/home/#{KD.whoami().profile.nickname}/Applications"
    appDir = FSHelper.createFileFromPath path, 'folder'
    appDir.fetchContents KD.utils.getTimedOutCallback (err, files)=>
      if err or not Array.isArray files or files.length is 0
        @putAppsToAppStorage {}
        callback()
      else
        apps  = []
        stack = []

        files.forEach (file)->
          if /\.kdapp$/.test(file.name) and file.type is 'folder'
            apps.push file

        apps.forEach (app)=>
          stack.push (cb)=>
            manifest = FSHelper.createFileFromPath "#{app.path}/manifest.json"
            manifest.fetchContents (err, response)->
              # shadowing the error is intentional here
              # to not to break the result of the stack
              cb null, response

        manifests = @constructor.manifests
        async.parallel stack, (err, result)=>
          result.forEach (rawManifest)->
            if rawManifest
              try
                manifest = JSON.parse rawManifest
                manifests["#{manifest.name}"] = manifest
              catch e
                console.warn "Manifest file is broken", e
          @putAppsToAppStorage manifests
          callback? null, manifests
    , ->
      log "Timeout reached for kite request"
      callback()

  fetchAppsFromDb:(callback)->
    return unless @appStorage

    @appStorage.fetchStorage (storage)=>

      apps = @appStorage.getValue 'apps'
      shortcuts = @appStorage.getValue 'shortcuts'

      justFetchApps = =>
        if apps and Object.keys(apps).length > 0
          @constructor.manifests = apps
          callback null, apps
        else
          callback new Error "There are no apps in the app storage."

      if not shortcuts
        @putDefaultShortcutsBack =>
          justFetchApps()
      else
        justFetchApps()

  fetchUpdateAvailableApps: (callback) ->
    return callback? null, @updateAvailableApps if @updateAvailableApps
    {publishedApps}      = @
    @updateAvailableApps = []

    @fetchApps (err, apps) =>
      for appName, app of apps
        if @isAppUpdateAvailable app.name, app.version
          @updateAvailableApps.push publishedApps[app.name]
      callback? null, @updateAvailableApps

  fetchCompiledAppSource:(manifest, callback)->

    indexJs = FSHelper.createFileFromPath "#{@getAppPath manifest}/index.js"
    indexJs.fetchContents callback

  # #
  # MISC
  # #

  refreshApps:(callback, redecorate=yes)->

    @constructor.manifests = {}
    KD.resetAppScripts()
    @fetchAppsFromFs (err, apps)=>
      @appStorage.fetchStorage =>
        @emit "AppsRefreshed", apps  if redecorate
      callback? err, apps

  removeShortcut:(shortcut, callback)->
    @appStorage.fetchValue 'shortcuts', (shortcuts)=>
      delete shortcuts[shortcut]
      @appStorage.setValue 'shortcuts', shortcuts, (err)=>
        callback err

  putDefaultShortcutsBack:(callback)->

    @appStorage.reset()
    @appStorage.setValue 'shortcuts', defaultShortcuts, callback

  putAppsToAppStorage:(apps)->

    @appStorage.setValue 'apps', apps

  defineApp:(name, script)->

    KD.registerAppScript name, script if script

  getAppScript:(manifest, callback = noop)->

    {name} = manifest

    if script = KD.getAppScript name
      callback null, script
    else
      @fetchCompiledAppSource manifest, (err, script)=>
        if err
          @compileApp name, (err)->
            callback err, script
        else
          @defineApp name, script
          callback err, script

  getPublishedApps: ->
    return unless KD.isLoggedIn()
    KD.remote.api.JApp.someWithRelationship {}, {}, (err, apps) =>
      @publishedApps = map = {}
      map[app.manifest.name] = app for app in apps

  isAppUpdateAvailable: (appName, appVersion) ->
    if @publishedApps[appName]
      return @utils.versionCompare appVersion, "lt", @publishedApps[appName].manifest.version

  updateUserApp: (manifest, callback) ->
    appName = manifest.name
    notification = new KDNotificationView
      type     : "mini"
      title    : "Updating #{appName}: Deleting old app files"
      duration : 120000

    folder = FSHelper.createFileFromPath manifest.path, "folder"
    folder.remove (err, res) =>
      return warn err if err
      @refreshApps =>
        notification.notificationSetTitle "Updating #{appName}: Fetching new app details"
        KD.remote.api.JApp.someWithRelationship { "manifest.name": appName }, {}, (err, app) =>
          notification.notificationSetTitle "Updating #{appName}: Updating app to latest version"
          @installApp app[0], "latest", =>
            @refreshApps()
            callback?()
            notification.setClass "success"
            notification.notificationSetTitle "#{appName} has been updated successfully"
            @utils.wait 3000, => notification.destroy()
            @appManager.open appName
      , yes

  # #
  # KITE INTERACTIONS
  # #

  runApp:(manifest, callback)->

    unless manifest
      warn "AppManager doesn't know what to run, no options passed!"
      return

    if @isAppUpdateAvailable(manifest.name, manifest.version) and not manifest.devMode and not @skipUpdate
      @showUpdateRequiredModal manifest
      return callback?()

    {options, name} = manifest

    putStyleSheets manifest

    @getAppScript manifest, (err, appScript)=>
      if err then warn err
      else
        if options and options.type is "tab"
          @appManager.open manifest.name,
            requestedFromAppsController : yes
          , (appInstance)->

            appView = appInstance.getView()
            id      = appView.getId()

            try
              # security please!
              do (appView)->
                eval "var appView = KD.instances[\"#{id}\"];\n\n" + appScript
            catch error
              # if not manifest.ignoreWarnings? # GG FIXME
              showError error
            callback?()
            return appView
        else
          try
            # security please!
            do ->
              eval appScript
          catch error
            showError error
          callback?()
          return null

        callback?()

  publishApp:(path, callback)->

    if not (KD.checkFlag('app-publisher') or KD.checkFlag('super-admin'))
      err = "You are not authorized to publish apps."
      log err
      callback? err
      return no

    manifest = getManifestFromPath(path)
    appName  = manifest.name

    @getAppScript manifest, (appScript)=>

      manifest   = @constructor.manifests[appName]
      appPath    = @getAppPath manifest
      options    =
        method   : "app.publish"
        withArgs : {appPath}

      @kiteController.run options, (err, res)=>
        if err
          warn err
          callback? err
        else
          manifest.authorNick = KD.whoami().profile.nickname
          jAppData     =
            title      : manifest.name        or "Application Title"
            body       : manifest.description or "Application description"
            identifier : manifest.identifier  or "com.koding.apps.#{__utils.slugify manifest.name}"
            manifest   : manifest

          @appManager.tell "Apps", "createApp", jAppData, (err, app)=>
            if err
              warn err
              callback? err
            else
              @appManager.open "Apps"
              @appManager.tell "Apps", "updateApps"
              callback?()

  compileApp:(name, callback)->

    compileOnServer = (app)=>
      return warn "#{name}: No such application!" unless app
      appPath = @getAppPath app

      loader = new KDNotificationView
        duration : 18000
        title    : "Compiling #{name}..."
        type     : "mini"

      @kiteController.run "kd app compile #{appPath}", (err, response)=>
        if not err
          loader.notificationSetTitle "Fetching compiled app..."
          @fetchCompiledAppSource app, (err, res)=>
            if not err
              @defineApp name, res
              loader.notificationSetTitle "App compiled successfully"
              loader.notificationSetTimer 2000
            callback? err
        else
          loader.destroy()

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

    unless @constructor.manifests[name]
      @fetchApps (err, apps)->
        compileOnServer apps[name]
    else
      compileOnServer @constructor.manifests[name]

  installApp:(app, version='latest', callback)->

    # add group membership control when group based apps feature is implemented!
    KD.requireMembership
      onFailMsg : "Login required to install Apps"
      onFail    : => callback yes
      callback  : => @fetchApps (err, manifests = {})=>
        if err
          warn err
          new KDNotificationView type : "mini", title : "There was an error, please try again later!"
          callback? err
        else
          if app.title in Object.keys(manifests)
            new KDNotificationView type : "mini", title : "App is already installed!"
            callback? msg : "App is already installed!"
          else
            if not app.approved and not KD.checkFlag 'super-admin'
              warn err = "This app is not approved, installation cancelled."
              callback? err
            else
              app.fetchCreator (err, acc)=>
                if err
                  callback? err
                else
                  options =
                    method        : "app.install"
                    withArgs      :
                      owner       : acc.profile.nickname
                      identifier  : app.manifest.identifier
                      appPath     : @getAppPath app.manifest
                      version     : app.versions.last

                  @kiteController.run options, (err, res)=>
                    if err then warn err
                    else
                      app.install (err)=>
                        warn err  if err
                        @appManager.open "StartTab"
                        @refreshApps()
                        callback?()

  # #
  # MAKE NEW APP
  # #

  newAppModal = null

  makeNewApp:(callback)->

    return callback? yes if newAppModal

    newAppModal = new KDModalViewWithForms
      title                       : "Create a new Application"
      content                     : "<div class='modalformline'>Please select the application type you want to start with.</div>"
      overlay                     : yes
      width                       : 400
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
                  unless newAppModal.modalTabs.forms.form.inputs.name.validate()
                    newAppModal.modalTabs.forms.form.buttons.Create.hideLoader()
                    return
                  name        = newAppModal.modalTabs.forms.form.inputs.name.getValue()
                  type        = newAppModal.modalTabs.forms.form.inputs.type.getValue()
                  name        = name.replace(/[^a-zA-Z0-9\/\-.]/g, '') if name
                  manifestStr = defaultManifest type, name
                  manifest    = JSON.parse manifestStr
                  appPath     = @getAppPath manifest

                  # FIXME Use default VM ~ GG
                  FSHelper.exists appPath, null, (err, exists)=>
                    if exists
                      newAppModal.modalTabs.forms.form.buttons.Create.hideLoader()
                      new KDNotificationView
                        type      : "mini"
                        cssClass  : "error"
                        title     : "App folder with that name is already exists, please choose a new name."
                        duration  : 3000
                    else
                      @prepareApplication {isBlank : type is "blank", name}, (err, response)=>
                        callback? err
                        newAppModal.modalTabs.forms.form.buttons.Create.hideLoader()
                        newAppModal.destroy()

            fields                :
              type                :
                label             : "Type"
                itemClass         : KDSelectBox
                type              : "select"
                name              : "type"
                defaultValue      : "sample"
                selectOptions     : [
                  { title : "Sample Application", value : "sample" }
                  { title : "Blank Application",  value : "blank"  }
                ]
              name                :
                label             : "Name:"
                name              : "name"
                placeholder       : "name your application..."
                validate          :
                  rules           :
                    regExp        : /^[a-z\d]+([-][a-z\d]+)*$/i
                  messages        :
                    regExp        : "For Application name only lowercase letters and numbers are allowed!"

    newAppModal.once "KDObjectWillBeDestroyed", ->
      newAppModal = null
      callback? yes

  _createChangeLog:(name)->
    today = new Date().format('yyyy-mm-dd')
    {profile} = KD.whoami()
    fullName = Encoder.htmlDecode "#{profile.firstName} #{profile.lastName}"

    """
     #{today} #{fullName} <@#{profile.nickname}>

        * #{name} (index.coffee): Application created.
    """

  prepareApplication:({isBlank, name}, callback)->

    type         = if isBlank then "blank" else "sample"
    name         = if name is "" then null else name
    name         = name.replace(/[^a-zA-Z0-9\/\-.]/g, '')  if name
    manifestStr  = defaultManifest type, name
    changeLogStr = @_createChangeLog name
    manifest     = JSON.parse manifestStr
    appPath      = @getAppPath manifest
    # log manifestStr

    stack = []

    manifestFile  = FSHelper.createFileFromPath "#{appPath}/manifest.json"
    changeLogFile = FSHelper.createFileFromPath "#{appPath}/ChangeLog"

    # Copy default app files (app Skeleton)
    stack.push (cb)=>
      @kiteController.run
        method    : "app.skeleton"
        withArgs  :
          type    : if isBlank then "blank" else "sample"
          appPath : appPath
        , cb

    stack.push (cb)=> manifestFile.save  manifestStr,  cb
    stack.push (cb)=> changeLogFile.save changeLogStr, cb

    async.series stack, (err, result) =>
      warn err  if err
      @emit "aNewAppCreated"  unless err
      callback? err, result

  # #
  # FORK / CLONE APP
  # #

  downloadAppSource:(path, callback)->

    @fetchApps =>
      manifest = getManifestFromPath path

      unless manifest
        callback new KDNotificationView type : "mini", title : "Please refresh your apps and try again!"
        return

      @kiteController.run
        kiteName    : "applications"
        method      : "downloadApp"
        withArgs    :
          owner     : manifest.authorNick
          appName   : manifest.name
          appPath   : @getAppPath manifest
          version   : manifest.version
      , (err, res)=>
        if err
          warn err
          callback? err
        else
          callback? null

  # #
  # HELPERS
  # #

  proxifyUrl = (url)-> KD.config.mainUri + '/-/imageProxy?url=' + encodeURIComponent(url)

  escapeFilePath = FSHelper.escapeFilePath

  putStyleSheets = (manifest)->
    {name, devMode} = manifest
    {stylesheets} = manifest.source if manifest.source

    return unless stylesheets

    $("head .app-#{__utils.slugify name}").remove()
    stylesheets.forEach (sheet)->
      if devMode
        urlToStyle = "https://#{KD.whoami().profile.nickname}.koding.com/.applications/#{__utils.slugify name}/#{__utils.stripTags sheet}?#{Date.now()}"
        $('head').append "<link class='app-#{__utils.slugify name}' rel='stylesheet' href='#{urlToStyle}'>"
      else
        if /(http)|(:\/\/)/.test sheet
          warn "external sheets cannot be used"
        else
          sheet = sheet.replace /(^\.\/)|(^\/+)/, ""
          $('head').append("<link class='app-#{__utils.slugify name}' rel='stylesheet' href='#{KD.appsUri}/#{manifest.authorNick or KD.whoami().profile.nickname}/#{__utils.stripTags name}/latest/#{__utils.stripTags sheet}'>")

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
    modal = new KDModalView
      title          : "App Update Available"
      content        : """
        <div class="app-update-modal">
          <p>An update available for #{manifest.name}. You can update the app now or you can continue to use old version you have.</p>
          <p><span class="app-update-warning">Warning:</span> Updating the app will delete it's current folder to install new version. This cannot be undone. If you have updated files, back up them now.</p>
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
        "Use This Version" :
          style      : "modal-clean-gray"
          callback   : =>
            @skipUpdate = yes
            @appManager.open manifest.name
            modal.destroy()
            @skipUpdate = no

  defaultManifest = (type, name)->
    {profile} = KD.whoami()
    fullName = Encoder.htmlDecode "#{profile.firstName} #{profile.lastName}"
    raw =
      devMode       : yes
      authorNick    : "#{KD.nick()}"
      multiple      : no
      background    : no
      hiddenHandle  : no
      openWith      : "lastActive"
      behavior      : "application"
      version       : "0.1"
      name          : "#{name or type.capitalize()}"
      identifier    : "com.koding.apps.#{__utils.slugify name or type}"
      path          : "~/Applications/#{name or type.capitalize()}.kdapp"
      homepage      : "#{profile.nickname}.koding.com/#{__utils.slugify name or type}"
      author        : "#{fullName}"
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
      menu: []

    json = JSON.stringify raw, null, 2

  defaultShortcuts =
    Ace           :
      name        : 'Ace'
      type        : 'koding-app'
      icon        : 'icn-ace.png'
      description : 'Code Editor'
      author      : 'Mozilla'
    Terminal      :
      name        : 'Terminal'
      type        : 'koding-app'
      icon        : 'icn-terminal.png'
      description : 'Koding Terminal'
      author      : 'Koding'
      path        : 'WebTerm'
    # CodeMirror    :
    #   name        : 'CodeMirror'
    #   type        : 'comingsoon'
    #   icon        : 'icn-codemirror.png'
    #   description : 'Code Editor'
    #   author      : 'Marijn Haverbeke'
    # yMacs         :
    #   name        : 'yMacs'
    #   type        : 'comingsoon'
    #   icon        : 'icn-ymacs.png'
    #   description : 'Code Editor'
    #   author      : 'Mihai Bazon'
    # Pixlr         :
    #   name        : 'Pixlr'
    #   type        : 'comingsoon'
    #   icon        : 'icn-pixlr.png'
    #   description : 'Image Editor'
    #   author      : 'Autodesk'
