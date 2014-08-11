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

    app = KD.config.apps[name]
    @putAppScript app, callback

  # This is the most important method to put & run additional apps on Koding
  # Please make sure about your changes on it.
  @putAppScript = (app, callback = noop)->

    if app.style
      @appendHeadElement 'style',  \
        { url:app.style, identifier:app.identifier, force: yes }

    if app.script
      @appendHeadElement 'script', \
        { url:app.script, identifier:app.identifier, force: yes }, callback

    return

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

    if jApp.status is 'verified'
      route = "/#{jApp.name}"
    else
      route = "/#{jApp.manifest.authorNick}/Apps/#{jApp.name}"


      KD.utils.defer ->

        if options.dontUseRouter
          KD.singletons.appManager.open jApp.name
        else
          KD.singletons.router.handleRoute route

        callback()

  @runExternalApp = (jApp, options = {}, callback = noop)->

    if jApp.status is 'verified' or jApp.manifest.authorNick is KD.nick()
      return @runApprovedApp jApp, options

    if jApp.status is 'not-verified'
      return new KDModalView
        title        : "Not a verified app"
        content      : "Only the owner of the app can run it."
        buttons      :
          "Got it"   :
            callback : -> @getDelegate().destroy()

    repo = jApp.manifest.repository.replace /^git\:\/\//, "https://"
    script = jApp.urls.script.replace KD.config.appsUri, "https://raw.github.com"
    authorLink = """
      <a href="/#{jApp.manifest.authorNick}">#{jApp.manifest.author}</a>
    """

    modal = new KDModalView
      title          : "Run #{jApp.manifest.name}"
      cssClass       : 'run-app-dialog'
      content        : """
        <p>
          <strong>
            Unverified apps are not moderated, they may be harmful.
          </strong>
        </p>
        <p>
          If you don't know #{authorLink}, it's recommended that
          you don't run this app.
        </p>
        <p>This app can <span>Access your files</span>,
          <span>Access your account</span>, <span>Change your account</span>,
          <span>Can post updates</span>.</p>
        <p>
          You can take a look at this application
          <a href="#{repo}" target="_blank">repository</a> and the
          <a href="#{script}" target="_blank">source code</a> from here.
        </p>
      """
      height         : "auto"
      overlay        : yes
      buttons        :
        Run          :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            $.ajax
              type     : "HEAD"
              url      : jApp.urls.script
              complete : (res, state)=>
                modal.destroy()
                if res.status is 200
                  @runApprovedApp jApp, options, -> modal.destroy()
                else
                  new KDNotificationView
                    title : "Application is not reachable"

        cancel       :
          style      : "modal-cancel"
          callback   : -> modal.destroy()

    modal.buttonHolder.addSubView new KDView
      partial  : "Do you still want to continue?"
      cssClass : "run-warning"

  @appendHeadElement = Promise.promisify (type, {identifier, url, force}, callback = (->)) ->

    identifier = identifier.replace /\./g, '_'
    domId      = "internal-#{type}-#{identifier}"
    vmName     = getVMNameFromPath url
    tagName    = type

    # Which means this is an invm-app
    if vmName

      file = FSHelper.createFileInstance path: url
      file.fetchContents (err, partial)=>
        return  if err

        obj = new KDCustomHTMLView {domId, tagName}
        obj.getElement().textContent = partial

        @destroyScriptElement type, identifier  if force

        if type is 'script'
          obj.once 'viewAppended', -> callback null
        else
          callback null

        KD.utils.defer -> obj.appendToSelector 'head'

    else
      delim = if /\?/.test url then "&" else "?"
      url = "#{ url }#{ delim }#{ KD.utils.uniqueId() }"
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
        load       = -> callback null

      @destroyScriptElement type, identifier  if force

      document.head.appendChild (new KDCustomHTMLView {
        domId, tagName, attributes, bind, load
      }).getElement()

      callback null  if type is 'style'

  @destroyScriptElement = (type, identifier)->
    (document.getElementById "internal-#{type}-#{identifier}")?.remove()

  @appendHeadElements = (options, callback)->
    {items, identifier} = options

    Promise.reduce(items, (acc, {url, type}, index) =>
      KodingAppsController.appendHeadElement type, {
        identifier : "#{identifier}-#{index}"
        url
      }

    , 0)
    # .timeout(5000)
    # .catch(warn)
    .nodeify callback

  # #
  # MAKE NEW APP
  # #

  newAppModal = null

  getAppPath:(manifest, escaped=no)->

    path = if 'string' is typeof manifest then manifest else manifest.path
    path = if /^~/.test path then "/home/#{KD.nick()}#{path.substr(1)}"\
           else path
    return FSHelper.escapeFilePath path  if escaped
    return path.replace /(\/+)$/, ""

  makeNewApp:(machine, callback)->

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
                  manifestStr = AppSkeleton.manifest type, name
                  manifest    = JSON.parse manifestStr
                  appPath     = @getAppPath manifest

                  appFolder   = FSHelper.createFileInstance {
                    path: appPath, machine, type: "folder"
                  }

                  appFolder.exists (err, exists)=>

                    if exists

                      form.buttons.Create.hideLoader()
                      new KDNotificationView
                        type      : "mini"
                        cssClass  : "error"
                        title     : "App folder with that name is already exists, please choose a new name."
                        duration  : 3000

                    else

                      @prepareApplication { machine, name }, (err, response)=>
                        callback? err, response
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

  prepareApplication:({ machine, name }, callback)->

    unless name
      return new KDNotificationView
        title : "Application name is not provided."

    type         = "blank"
    appname      = KD.utils.slugify name.replace /[^a-zA-Z]/g, ''
    APPNAME      = appname.capitalize()
    manifestStr  = AppSkeleton.manifest type, APPNAME
    changeLogStr = AppSkeleton.changeLog APPNAME
    manifest     = JSON.parse manifestStr
    appPath      = @getAppPath manifest

    machine.getBaseKite()

    .exec
      command : "mkdir -p #{appPath}/resources"

    .then ->
      indexFile = FSHelper.createFileInstance {
        path: "#{appPath}/index.coffee", machine
      }
      content = AppSkeleton.indexCoffee
                  .replace /\%\%APPNAME\%\%/g, APPNAME
                  .replace /\%\%appname\%\%/g, appname
                  .replace /\%\%AUTHOR\%\%/g , KD.nick()

      indexFile.save content

    .then ->
      styleFile = FSHelper.createFileInstance {
        path: "#{appPath}/resources/style.css", machine
      }
      content = AppSkeleton.styleCss
                  .replace /\%\%appname\%\%/g, appname
      styleFile.save content

    .then ->
      readmeFile = FSHelper.createFileInstance {
        path: "#{appPath}/README.md", machine
      }
      author  = Encoder.htmlDecode(KD.utils.getFullnameFromAccount())
      content = AppSkeleton.readmeMd
        .replace /\%\%APPNAME\%\%/g, APPNAME
        .replace /\%\%AUTHOR_FULLNAME\%\%/g , author
      readmeFile.save content

    .then ->

      FSHelper.createFileInstance {
        path: "#{appPath}/manifest.json", machine
      }

      .save manifestStr

    .then ->

      FSHelper.createFileInstance {
        path: "#{appPath}/ChangeLog", machine
      }

      .save manifestStr

    .then ->
      return { appPath }

    .catch (err) ->
      warn err

    .nodeify callback

  getVMNameFromPath = (path)-> (/^\[([^\]]+)\]/g.exec path)?[1]

  @getAppInfoFromPath = (path, showWarning = no)->

    return  unless path

    vm    = getVMNameFromPath path
    path  = FSHelper.plainPath path
    reg   = /// ^\/home\/#{KD.nick()}\/Applications\/(.*)\.kdapp ///
    parts = reg.exec path

    unless parts
      if showWarning then new KDNotificationView
        title : "Failed to find app information from given path"
        type  : "mini"
      return

    [path, name] = parts[0..1]
    return {
      path, name,
      fullPath : "[#{vm}]#{path}"
      vm
    }

  @installKDC = ->

    modal = new ModalViewWithTerminal
      title   : "Koding app compiler is not installed in your VM."
      width   : 500
      overlay : yes
      terminal:
        hidden: yes
      content : """
                  <p>
                    If you want to install it now, click <strong>Install Compiler</strong> button.
                  </p>
                  <p>
                    <strong>Remember to enter your password when asked.</strong>
                  </p>
                """
      buttons:
        "Install Compiler":
          cssClass: "modal-clean-green"
          callback: =>
            modal.run "sudo npm install -g kdc; echo $?|kdevent;" # find a clean/better way to do it.

    modal.on "terminal.event", (data)=>
      if data is "0"
        new KDNotificationView title: "Installed successfully!"
        modal.destroy()
      else
        new KDNotificationView
          title   : "An error occured."
          content : "Something went wrong while installing Koding App Compiler. Please try again."

  @compileAppOnServer = (path, callback)->

    app = KodingAppsController.getAppInfoFromPath path, yes
    return  unless app

    loader = new KDNotificationView
      duration : 18000
      title    : "Compiling #{app.name}..."
      type     : "mini"

    {vmController} = KD.singletons
    vmController.run
      withArgs : "kdc #{app.path}"
      vmName   : app.vm
    , (err, response)->

      if err or not response

        loader.notificationSetTitle "An unknown error occured"
        loader.notificationSetTimer 2000
        callback? err, app
        warn err

      else if response.exitStatus is 0

        loader.notificationSetTitle "App compiled successfully"
        loader.notificationSetTimer 2000
        callback null, app

      else

        loader.destroy()

        err = response.stderr or response.stdout

        if response.exitStatus is 127
          KodingAppsController.installKDC()
          callback? { message: "KDC is not installed: #{err}" }
          return

        new KDModalView
          title    : "An error occured while compiling #{app.name}"
          width    : 600
          overlay  : yes
          cssClass : 'compiler-modal'
          content  : "<pre>#{err}</pre>"

        callback? { message: "Failed to compile: #{err}" }, app

  @createJApp = ({path, target}, callback)->

    app = @getAppInfoFromPath path
    return  unless app
    {name} = app

    @compileAppOnServer path, (err)=>
      return warn err  if err

      @fetchManifest "#{app.path}/manifest.json", (err, manifest)->

        if err? or not manifest
          return new KDNotificationView
            title : "Failed to fetch application manifest."

        unless target is 'production'

          return KD.remote.api.JNewApp.publish {
            name, url: app.fullPath, manifest
          }, callback

        modal = new KodingAppSelectorForGitHub
          title        : "Select repository of #{app.name}.kdapp"
          customFilter : ///#{app.name}\.kdapp$///

        modal.once "RepoSelected", (repo)->

          GitHub.getLatestCommit repo.name, (err, commit)->

            if not err and commit

              url = "#{KD.config.appsUri}/#{repo.full_name}/#{commit.sha}/"
              manifest.commitId = commit.sha
              KD.remote.api.JNewApp.publish { name, url, manifest }, callback

            else

              new KDNotificationView
                title : "Failed to fetch latest commit for #{repo.full_name}"

            modal.destroy()

  @fetchManifest = (path, callback = noop)->

    manifest = FSHelper.createFileInstance path:  path
    manifest.fetchContents (err, response)=>

      return warn err  if err

      try
        manifest = JSON.parse response
      catch e
        return callback {
          message : "Failed to parse manifest.json"
          name    : "JSONPARSEERROR"
          details : e
        }

      callback null, manifest


class AppSkeleton

  @manifest = (type, name)->

    {profile} = KD.whoami()
    raw =
      background    : no
      behavior      : "application"
      version       : "0.1"
      title         : "#{name or type.capitalize()}"
      name          : "#{name or type.capitalize()}"
      identifier    : "com.koding.apps.#{utils.slugify name or type}"
      path          : "~/Applications/#{name or type.capitalize()}.kdapp"
      homepage      : "#{profile.nickname}.#{KD.config.userSitesDomain}/#{utils.slugify name or type}"
      repository    : "git://github.com/#{profile.nickname}/#{utils.slugify name or type}.kdapp.git"
      description   : "#{name or type} : a Koding application created with the #{type} template."
      category      : "web-app" # can be web-app, add-on, server-stack, framework, misc
      source        :
        blocks      :
          app       :
            files   : [ "./index.coffee" ]
        stylesheets : [ "./resources/style.css" ]
      options       :
        type        : "tab"
      icns          :
        "128"       : "./resources/icon.128.png"
      fileTypes     : []

    json = JSON.stringify raw, null, 2


  @changeLog = (name)->

    today = new Date().format('yyyy-mm-dd')
    {profile} = KD.whoami()
    fullName  = KD.utils.getFullnameFromAccount()

    """
     #{today} #{fullName} <@#{profile.nickname}>

        * #{name} (index.coffee): Application created.
    """


  @indexCoffee =

    """
      class %%APPNAME%%MainView extends KDView

        constructor:(options = {}, data)->
          options.cssClass = '%%appname%% main-view'
          super options, data

        viewAppended:->
          @addSubView new KDView
            partial  : "Welcome to %%APPNAME%% app!"
            cssClass : "welcome-view"

      class %%APPNAME%%Controller extends AppController

        constructor:(options = {}, data)->
          options.view    = new %%APPNAME%%MainView
          options.appInfo =
            name : "%%APPNAME%%"
            type : "application"

          super options, data

      do ->

        # In live mode you can add your App view to window's appView
        if appView?

          view = new %%APPNAME%%MainView
          appView.addSubView view

        else

          KD.registerAppClass %%APPNAME%%Controller,
            name     : "%%APPNAME%%"
            routes   :
              "/:name?/%%APPNAME%%" : null
              "/:name?/%%AUTHOR%%/Apps/%%APPNAME%%" : null
            dockPath : "/%%AUTHOR%%/Apps/%%APPNAME%%"
            behavior : "application"
    """

  @styleCss =

    """
      .%%appname%%.main-view {
        background: white;
      }

      .%%appname%% .welcome-view {

        background: #eee;

        height: auto;
        width: auto;
        max-width: 300px;

        margin: 50px auto;

        border: 1px solid #ccc;
        border-radius: 4px;

        padding:10px;

        text-align:center;

      }
    """

  @readmeMd =

    """
      %%APPNAME%%
      -----------

      Yet another awesome Koding application! by %%AUTHOR_FULLNAME%%

    """
