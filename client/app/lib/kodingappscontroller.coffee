kd                         = require 'kd'
KDController               = kd.Controller
KDCustomHTMLView           = kd.CustomHTMLView
KDModalView                = kd.ModalView
KDModalViewWithForms       = kd.ModalViewWithForms
KDNotificationView         = kd.NotificationView
KDView                     = kd.View
htmlencode                 = require 'htmlencode'
Promise                    = require 'bluebird'
$                          = require 'jquery'
globals                    = require 'globals'
getFullnameFromAccount     = require './util/getFullnameFromAccount'
registerAppClass           = require './util/registerAppClass'
remote                     = require('./remote').getInstance()
nick                       = require './util/nick'
AppSkeleton                = require './appskeleton'
FSHelper                   = require './util/fs/fshelper'
GitHub                     = require './extras/github/github'
KodingAppSelectorForGitHub = require './commonviews/kodingappselectorforgithub'
ModalViewWithTerminal      = require './commonviews/modalviewwithterminal'

module.exports =

class KodingAppsController extends KDController

  name    = "KodingAppsController"
  version = "0.1"

  registerAppClass this, {name, version, background: yes}

  constructor:->
    super

    # appStorage = KD.getSingleton 'appStorageController'
    # @storage   = appStorage.storage "Applications", version

    # @storage.fetchStorage (storage)=>
    #   @apps = @storage.getValue('installed') or {}
    #   @apps or= {}

    #   @emit 'ready'

  @loadInternalApp = (name, callback) ->

    unless globals.config.apps[name]
      kd.warn message = "#{name} is not available to run!"
      return callback {message}

    if name.capitalize() in Object.keys globals.appClasses
      kd.warn "#{name} is already imported"
      return callback null

    app = globals.config.apps[name]

    @putAppScript app, (err, res) =>
      AppClass = require res.app.identifier
      register = (klass) ->
        registerAppClass klass
        callback err, res

      if dependencies = AppClass.options?.dependencies
      then @loadDependencies dependencies, -> register AppClass
      else register AppClass


  @loadDependencies = (dependencies, callback) ->
    sinkrow = require 'sinkrow'
    queue   = []

    for dependency in dependencies
      fn = @loadInternalApp.bind this, dependency, -> queue.fin()
      queue.push fn

    sinkrow.dash queue, callback

  ## This is the most important method to put & run additional apps on Koding
  ## Please make sure about your changes on it.
  @putAppScript = (app, callback = kd.noop)->

    if app.style
      cb = if app.script then kd.noop else callback
      @appendHeadElement 'style',  \
        { app: app, url:app.style, identifier:app.identifier, force: yes }, cb

    if app.script
      @appendHeadElement 'script', \
        { app: app, url:app.script, identifier:app.identifier, force: yes }, callback

    return

  @unloadAppScript = (app, callback = kd.noop)->

    identifier = app.identifier.replace /\./g, '_'

    @destroyScriptElement "style", identifier
    @destroyScriptElement "script", identifier

    kd.utils.defer -> callback()

  @runApprovedApp = (jApp, options = {}, callback = kd.noop)->

    return kd.warn "JNewApp not found!"  unless jApp

    {script, style} = jApp.urls
    return kd.warn "Script not found! on #{jApp}"  unless script

    app = {
      name : jApp.name
      script, style
      identifier : jApp.identifier
    }

    if jApp.status is 'verified'
      route = "/#{jApp.name}"
    else
      route = "/#{jApp.manifest.authorNick}/Apps/#{jApp.name}"


      kd.utils.defer ->

        if options.dontUseRouter
          kd.singletons.appManager.open jApp.name
        else
          kd.singletons.router.handleRoute route

        callback()

  @runExternalApp = (jApp, options = {}, callback = kd.noop)->

    if jApp.status is 'verified' or jApp.manifest.authorNick is nick()
      return @runApprovedApp jApp, options

    if jApp.status is 'not-verified'
      return new KDModalView
        title        : "Not a verified app"
        content      : "Only the owner of the app can run it."
        buttons      :
          "Got it"   :
            callback : -> @getDelegate().destroy()

    repo = jApp.manifest.repository.replace /^git\:\/\//, "https://"
    script = jApp.urls.script.replace globals.config.appsUri, "https://raw.github.com"
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
          style      : "solid red medium"
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
          style      : "solid light-gray medium"
          callback   : -> modal.destroy()

    modal.buttonHolder.addSubView new KDView
      partial  : "Do you still want to continue?"
      cssClass : "run-warning"

  @appendHeadElement = Promise.promisify (type, {app, identifier, url, force}, callback = (->)) ->

    identifier  = identifier.replace /\./g, '_'
    domId       = "internal-#{type}-#{identifier}"
    vmName      = getVMNameFromPath url
    tagName     = type

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

        kd.utils.defer -> obj.appendToSelector 'head'

    else
      bind = ''
      load = kd.noop

      if type is 'style'
        tagName    = 'link'
        attributes =
          rel      : 'stylesheet'
          href     : url
        bind       = "load"
        load       = -> callback null, {app, type, url}
      else
        attributes =
          type     : "text/javascript"
          src      : url
        bind       = "load"
        load       = -> callback null, {app, type, url}

      @destroyScriptElement type, identifier  if force

      global.document.head.appendChild (new KDCustomHTMLView {
        domId, tagName, attributes, bind, load
      }).getElement()

  @destroyScriptElement = (type, identifier)->
    (global.document.getElementById "internal-#{type}-#{identifier}")?.remove()

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
    path = if /^~/.test path then "/home/#{nick()}#{path.substr(1)}"\
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
                cssClass          : "solid light-gray medium"
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
    appname      = kd.utils.slugify name.replace /[^a-zA-Z]/g, ''
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
                  .replace /\%\%AUTHOR\%\%/g , nick()

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
      author  = htmlencode.htmlDecode(getFullnameFromAccount())
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
      kd.warn err

    .nodeify callback

  getVMNameFromPath = (path)-> (/^\[([^\]]+)\]/g.exec path)?[1]

  @getAppInfoFromPath = (path, showWarning = no)->

    return  unless path

    vm    = getVMNameFromPath path
    path  = FSHelper.plainPath path
    reg   = /// ^\/home\/#{nick()}\/Applications\/(.*)\.kdapp ///
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
          cssClass: "solid green medium"
          callback: =>
            modal.run "sudo npm install -g kdc; echo $?|kdevent;" # find a clean/better way to do it.

    modal.on "terminal.event", (data)=>
      if data is "0"
        new KDNotificationView title: "Installed successfully!"
        modal.destroy()
      else
        new KDNotificationView
          title   : "An error occurred."
          content : "Something went wrong while installing Koding App Compiler. Please try again."

  @createJApp = ({path, target}, callback)->

    app = @getAppInfoFromPath path
    return  unless app
    {name} = app

    @compileAppOnServer path, (err)=>
      return kd.warn err  if err

      @fetchManifest "#{app.path}/manifest.json", (err, manifest)->

        if err? or not manifest
          return new KDNotificationView
            title : "Failed to fetch application manifest."

        unless target is 'production'

          return remote.api.JNewApp.publish {
            name, url: app.fullPath, manifest
          }, callback

        modal = new KodingAppSelectorForGitHub
          title        : "Select repository of #{app.name}.kdapp"
          customFilter : ///#{app.name}\.kdapp$///

        modal.once "RepoSelected", (repo)->

          GitHub.getLatestCommit repo.name, (err, commit)->

            if not err and commit

              url = "#{globals.config.appsUri}/#{repo.full_name}/#{commit.sha}/"
              manifest.commitId = commit.sha
              remote.api.JNewApp.publish { name, url, manifest }, callback

            else

              new KDNotificationView
                title : "Failed to fetch latest commit for #{repo.full_name}"

            modal.destroy()

  @fetchManifest = (path, callback = kd.noop)->

    manifest = FSHelper.createFileInstance path:  path
    manifest.fetchContents (err, response)=>

      return kd.warn err  if err

      try
        manifest = JSON.parse response
      catch e
        return callback {
          message : "Failed to parse manifest.json"
          name    : "JSONPARSEERROR"
          details : e
        }

      callback null, manifest




