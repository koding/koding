KDApps = {}

class KodingAppsController extends KDController

  escapeFilePath = FSHelper.escapeFilePath

  defaultManifest = (type, name)->
    {profile} = KD.whoami()
    fullName = Encoder.htmlDecode "#{profile.firstName} #{profile.lastName}"
    raw =
      devMode       : yes
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

    json = JSON.stringify raw, null, 2

  @manifests = {}

  # #
  # HELPERS
  # #

  getAppPath:(manifest)->

    {profile} = KD.whoami()
    path = if 'string' is typeof manifest then manifest else manifest.path
    path = if /^~/.test path then "/Users/#{profile.nickname}#{path.substr(1)}" else path
    return path.replace /(\/+)$/, ""

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

    @kiteController = @getSingleton('kiteController')

    appManager.addAppInstance "KodingAppsController", @

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
            else
              callback null, apps
        else
          callback? err, apps

  fetchAppsFromFs:(callback)->

    path = "/Users/#{KD.whoami().profile.nickname}/Applications"
    KD.utils.wait 6000, callback

    @kiteController.run "ls #{escapeFilePath path} -lpva", (err, response)=>
      if err
        @putAppsToAppStorage {}
        warn err
        callback err
      else
        files = FSHelper.parseLsOutput [path], response
        apps  = []
        stack = []

        files.forEach (file)->
          if /\.kdapp$/.test file.name
            apps.push file

        apps.forEach (app)=>
          stack.push (cb)=>
            manifestFile = if app.type is "folder" then FSHelper.createFileFromPath "#{app.path}/.manifest" else app
            manifestFile.fetchContents (err, response)->
              cb null, response # shadowing the error is intentional here to not to break the results of the stack

        manifests = @constructor.manifests
        async.parallel stack, (err, results)=>
          warn err if err
          results.forEach (rawManifest)->
            if rawManifest
              try
                manifest = JSON.parse rawManifest
                manifests["#{manifest.name}"] = manifest
              catch e
                console.warn "Manifest file is broken", e
          @putAppsToAppStorage manifests
          callback? null, manifests

  fetchAppsFromDb:(callback)->

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

  fetchCompiledApp:(manifest, callback)->

    {name} = manifest
    appPath = @getAppPath manifest
    indexJsPath = "#{appPath}/index.js"
    @kiteController.run "cat #{escapeFilePath indexJsPath}", (err, response)=>
      callback err, response

  # #
  # MISC
  # #

  refreshApps:(callback)->

    @constructor.manifests = {}
    KDApps = {}
    @fetchAppsFromFs (err, apps)=>
      @appStorage.fetchStorage =>
        @emit "AppsRefreshed", apps
      if not err
        callback? err, apps
      else
        callback err

  removeShortcut:(shortcut, callback)->
    @appStorage.fetchValue 'shortcuts', (shortcuts)=>
      delete shortcuts[shortcut]
      @appStorage.setValue 'shortcuts', shortcuts, (err)=>
        callback err

  putDefaultShortcutsBack:(callback)->

    shortcuts       =
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
      CodeMirror    :
        name        : 'CodeMirror'
        type        : 'comingsoon'
        icon        : 'icn-codemirror.png'
        description : 'Code Editor'
        author      : 'Marijn Haverbeke'
      yMacs         :
        name        : 'yMacs'
        type        : 'comingsoon'
        icon        : 'icn-ymacs.png'
        description : 'Code Editor'
        author      : 'Mihai Bazon'
      Pixlr         :
        name        : 'Pixlr'
        type        : 'comingsoon'
        icon        : 'icn-pixlr.png'
        description : 'Image Editor'
        author      : 'Autodesk'

    @appStorage.reset()
    @appStorage.setValue 'shortcuts', shortcuts, callback

  putAppsToAppStorage:(apps)->

    @appStorage.setValue 'apps', apps

  defineApp:(name, script)->

    KDApps[name] = script if script

  getAppScript:(manifest, callback = noop)->

    {name} = manifest

    if KDApps[name]
      callback null, KDApps[name]
    else
      @fetchCompiledApp manifest, (err, script)=>
        if err
          @compileApp name, (err)->
            callback err, KDApps[name]
        else
          @defineApp name, script
          callback err, KDApps[name]

  # #
  # KITE INTERACTIONS
  # #

  runApp:(manifest, callback)->

    {options, name, devMode} = manifest
    {stylesheets} = manifest.source if manifest.source

    proxifyUrl=(url)->
      "https://api.koding.com/1.0/image.php?url="+ encodeURIComponent(url)

    if stylesheets
      $("head .app-#{__utils.slugify name}").remove()
      stylesheets.forEach (sheet)->
        if devMode
          urlToStyle = "https://#{KD.whoami().profile.nickname}.koding.com/.applications/#{__utils.slugify name}/#{__utils.stripTags sheet}"
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

    @getAppScript manifest, (err, appScript)=>
      if err then warn err
      else
        if options and options.type is "tab"
          # mainView = @getSingleton('mainView')
          # mainView.mainTabView.showPaneByView
          #   name         : manifest.name
          #   hiddenHandle : no
          #   type         : "application"
          # , (appView = new KDView)

          @propagateEvent
            KDEventType     : 'ApplicationWantsToBeShown'
            globalEvent     : yes
          ,
            options         :
              name          : manifest.name
              hiddenHandle  : no
              type          : 'application'
            data            : appView = new KDView

          appView.on 'ViewClosed', =>
            @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : appView
            appManager.removeOpenTab appView
            appView.destroy()

          try
            # security please!
            do (appView)->
              appScript = "var appView = KD.instances[\"#{appView.getId()}\"];\n\n"+appScript
              eval appScript
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

        log "App to run:", name
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

      manifest        = @constructor.manifests[appName]
      userAppPath     = @getAppPath manifest
      options         =
        kiteName      : "applications"
        method        : "publishApp"
        withArgs      :
          version     : manifest.version
          appName     : manifest.name
          userAppPath : userAppPath
          profile     : KD.whoami().profile

      @kiteController.run options, (err, res)=>
        log "app is being published"
        if err
          warn err
          callback? err
        else
          manifest.authorNick = KD.whoami().profile.nickname
          jAppData   =
            title      : manifest.name        or "Application Title"
            body       : manifest.description or "Application description"
            identifier : manifest.identifier  or "com.koding.apps.#{__utils.slugify manifest.name}"
            manifest   : manifest

          appManager.tell "Apps", "createApp", jAppData, (err, app)=>
            if err
              warn err
              callback? err
            else
              # log app, "app published"
              appManager.openApplication "Apps"
              appManager.tell "Apps", "updateApps"
              callback?()

  approveApp:(app, callback)->

    if not KD.checkFlag('super-admin')
      err = "You are not authorized to approve apps."
      log err
      callback? err
      return no

    options         =
      kiteName      : "applications"
      method        : "approveApp"
      withArgs      :
        version     : app.manifest.version
        appName     : app.manifest.name
        authorNick  : app.manifest.authorNick

    @kiteController.run options, (err, res)=>
      log "app is being approved"
      if err
        warn err
        callback? err
      else
        log app, "app approved"
        callback?()

  compileApp:(name, callback)->

    compileOnServer = (app)=>
      return warn "#{name}: No such application!" unless app
      appPath = @getAppPath app

      loader = new KDNotificationView
        duration : 18000
        title    : "Compiling #{name}..."
        type     : "mini"

      @kiteController.run
        kiteName  : "applications"
        method    : "compileApp"
        withArgs  : {appPath}
      , (err)=>
        if not err
          loader.notificationSetTitle "Fetching compiled app..."
          @fetchCompiledApp app, (err, res)=>
            if not err
              @defineApp name, res
              loader.notificationSetTitle "App compiled successfully"
              loader.notificationSetTimer 2000
            callback? err
        else
          loader.destroy()

          if err.details?.details?
            details = """<pre>ERROR: #{err.details.details} <br/>
                              FILE : #{err.details.file} <br/></pre>"""
          else if err.details?
            details = "<pre>#{err.details}</pre>"
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
      @kiteController.run "test -d #{escapeFilePath @getAppPath @constructor.manifests[name]}", (err)=>
        if err
          new KDNotificationView
            title    : "App list is out-dated, refreshing apps..."
            duration : 2000
          @refreshApps noop
        else
          compileOnServer @constructor.manifests[name]

  installApp:(app, version='latest', callback)->

    @fetchApps (err, manifests = {})=>
      if err
        warn err
        new KDNotificationView type : "mini", title : "There was an error, please try again later!"
        callback? err
      else
        # log manifests
        if app.title in Object.keys(manifests)
          new KDNotificationView type : "mini", title : "App is already installed!"
          callback? msg : "App is already installed!"
        else
          # log "installing the app: #{app.title}"
          if not app.approved and not KD.checkFlag 'super-admin'
            err = "This app is not approved, installation cancelled."
            log err
            callback? err
          else
            app.fetchCreator (err, acc)=>
              # log err, acc, ">>>>"
              if err
                callback? err
              else
                options =
                  kiteName      : "applications"
                  method        : "installApp"
                  withArgs      :
                    owner       : acc.profile.nickname
                    appPath     : @getAppPath app.manifest
                    appName     : app.manifest.name
                    version     : version
                # log "asking kite to install", options
                @kiteController.run options, (err, res)=>
                  log "Kite response: ", err, res
                  if err then warn err
                  else
                    app.install (err)=>
                      log err if err
                      # log callback
                      # This doesnt work :#
                      appManager.openApplication "StartTab"
                      @refreshApps()
                      # callback?()

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

                  FSItem.doesExist appPath, (err, exists)=>
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

  prepareApplication:({isBlank, name}, callback)->

    type        = if isBlank then "blank" else "sample"
    name        = if name is "" then null else name
    name        = name.replace(/[^a-zA-Z0-9\/\-.]/g, '') if name
    manifestStr = defaultManifest type, name
    manifest    = JSON.parse manifestStr
    appPath     = @getAppPath manifest
    # log manifestStr

    FSItem.create appPath, "folder", (err, fsFolder)=>
      if err then warn err
      else
        stack = []
        today = new Date().format('yyyy-mm-dd')
        {profile} = KD.whoami()
        fullName = Encoder.htmlDecode "#{profile.firstName} #{profile.lastName}"

        stack.push (cb)=>
          @kiteController.run
            method      : "uploadFile"
            withArgs    :
              path      : escapeFilePath "#{fsFolder.path}/.manifest"
              contents  : manifestStr
          , cb

        stack.push (cb)=>
          @kiteController.run
            method      : "uploadFile"
            withArgs    :
              path      : escapeFilePath "#{fsFolder.path}/ChangeLog"
              contents  : """
                              #{today} #{fullName} <@#{profile.nickname}>

                                  * #{name} (index.coffee): Application created.
                          """
          , cb

        # Copy default app files (app Skeleton)
        stack.push (cb)=>
          @kiteController.run
            kiteName  : "applications"
            method    : "copyAppSkeleton"
            withArgs  :
              type    : if isBlank then "blank" else "sample"
              appPath : appPath
            , cb

        async.parallel stack, (error, result) =>
          if err then warn err
          @emit "aNewAppCreated" if not err
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


  # cloneApp:(path, callback)->

  #   @fetchApps (err, manifests = {})=>
  #     if err
  #       warn err
  #       new KDNotificationView type : "mini", title : "There was an error, please try again later!"
  #       callback? err
  #     else
  #       manifest = getManifestFromPath path

  #       {repo} = manifest

  #       if /^git/.test repo      then repoType = "git"
  #       else if /^svn/.test repo then repoType = "svn"
  #       else if /^hg/.test repo  then repoType = "hg"
  #       else
  #         err = "Unsupported repository specified, quitting!"
  #         new KDNotificationView type : "mini", title : err
  #         callback? err
  #         return no

  #       appPath = "/Users/#{KD.whoami().profile.nickname}/Applications/#{manifest.name}.kdapp"
  #       appBackupPath = "#{appPath}.old#{@utils.getRandomNumber 9999}"

  #       @kiteController.run "mv #{escapeFilePath appPath} #{escapeFilePath appBackupPath}" , (err, response)->
  #         if err then warn err
  #         @kiteController.run "#{forkRepoCommandMap()[repoType]} #{repo} #{escapeFilePath getAppPath manifest}", (err, response)->
  #           if err then warn err
  #           else
  #             log response, "App cloned!"
  #           callback? err, response
