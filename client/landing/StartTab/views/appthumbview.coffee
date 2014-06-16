class StartTabAppThumbView extends KDCustomHTMLView

  JView.mixin @prototype

  constructor:(options, data)->

    options.tagName    = 'figure'

    if data.disabled?
      options.cssClass += ' disabled'
    else if data.catalog?
      options.cssClass += ' appcatalog'

    super options, data

    @appsController = KD.getSingleton("kodingAppsController")

    {icns, name, identifier, version, author, description, title,
     authorNick, additionalinfo} = manifest = @getData()

    additionalinfo or= ''
    description    or= ''
    version        or= ''
    appPath          = ''

    authorNick or= KD.nick()

    resourceRoot = "#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}"

    if manifest.devMode
      resourceRoot = "https://#{authorNick}.#{KD.config.userSitesDomain}/.applications/#{utils.slugify name}"

    thumb = "#{KD.apiUri + '/a/images/default.app.thumb.png'}"

    for size in [512, 256, 160, 128, 64]
      if icns and icns[String size]
        thumb = "#{resourceRoot}/#{icns[String size]}"
        break

    @img = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      attributes  :
        src       : encodeURI thumb

    @img.off 'error'
    @img.on  'error', ->
      @setAttribute "src", "/a/images/default.app.thumb.png"

    @loader = new KDLoaderView
      size          :
        width       : 40

    if name isnt title
      appPath = Encoder.XSSEncode "/home/#{KD.nick()}/Applications/#{name}"
      appPath = "<p class='app-path'><cite>#{appPath}</cite></p>"

    @info = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon info"
      tooltip  :
        offset :
          top  : 4
          left : -5
        title  : """
          <div class='app-tip'>
            <header><strong>#{Encoder.XSSEncode title} #{Encoder.XSSEncode version}</strong> <cite>by #{Encoder.XSSEncode author}</cite></header>
            <p class='app-desc'>#{Encoder.XSSEncode description.slice(0,200)}#{if description.length > 199 then '...' else ''}</p>
            #{if additionalinfo then "<cite>#{Encoder.XSSEncode additionalinfo}</cite>" else ""}
            #{appPath}
          <div>
          """
      click    : -> no

    @delete = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon delete"
      tooltip  :
        title  : "Click to delete"
        offset :
          top  : 4
          left : -5
      click    : =>
        @delete.getTooltip().hide()
        @deleteModal = new KDModalView
          title          : "Delete #{Encoder.XSSEncode title}"
          content        : "<div class='modalformline'>Are you sure you want to delete <strong>#{Encoder.XSSEncode title}</strong> application?</div>"
          height         : "auto"
          overlay        : yes
          buttons        :
            Delete       :
              style      : "modal-clean-red"
              loader     :
                color    : "#ffffff"
                diameter : 16
              callback   : => @appDeleteCall manifest
            cancel       :
              style      : "modal-cancel"
              callback   : =>
                @deleteModal.destroy()

    @updateView  = new KDCustomHTMLView
      cssClass   : "top-badge"
      click      : (e) =>
        e.preventDefault()
        e.stopPropagation()
        jApp = @appsController.publishedApps[manifest.name]
        KD.getSingleton("appManager").open "Apps", =>
          KD.getSingleton("router").handleRoute "/Apps/#{manifest.slug}", state: jApp

    {experimental, devMode} = @getData()

    if experimental
      @experimentalView = new KDCustomHTMLView
        cssClass   : "top-badge orange"
        partial    : "Experimental"
        tooltip    :
          title    : "This is an experimental app, click for help."
        click      : (e) =>
          e.stopPropagation()
          new KDModalView
            overlay  : yes
            width    : 500
            title    : "Experimental App"
            content  : """
              <div class='modalformline'>
                <p>This is an experimental app, you can spot bugs or the app may break the ux and could force you to reload or it can even DAMAGE your files. If you're 100% sure, go ahead and use this app!</p>
              </div>
            """
    else
      @experimentalView = new KDView

    if devMode
      @compile = new KDCustomHTMLView
        tagName  : "span"
        cssClass : "icon compile"
        tooltip  :
          title  : "Click to compile"
          offset :
            top  : 4
            left : -5
        click    : =>
          @showLoader()
          @appsController.compileApp manifest.name, (err)=>
            @hideLoader()
          no

      @devModeView = new KDCustomHTMLView
        partial  : "Dev Mode"
        cssClass : "top-badge gray"
        tooltip  :
          title  : "Dev-Mode enabled, click for help."
        click    : (e) ->
          e.stopPropagation()
          new KDModalView
            overlay  : yes
            width    : 500
            title    : "Dev Mode"
            content  : utils.expandUrls """<div class='modalformline'><p>
                          If you set <code>devMode</code> to <code>true</code>
                          in the <code>.manifest</code> file, you can compile
                          this app on the Koding Application servers. When you
                          compile your app, shared resources like stylesheets
                          or images in your app will be served from
                          #{resourceRoot} </p></div>"""
      @experimentalView.destroy()
      @experimentalView = new KDView
    else
      @compile     = new KDView
      @devModeView = new KDView
      if @appsController.publishedApps then @putUpdateView()
      else @appsController.on "UserAppModelsFetched", (apps) =>
        @putUpdateView()

  putUpdateView: ->
    manifest          = @getData()
    isUpdateAvailable = @appsController.isAppUpdateAvailable manifest.name, manifest.version
    return unless isUpdateAvailable

    updateClass       = "green"
    updateText        = "Update Available"
    updateTooltip     = "An update available for this app. Click here to see."

    if @appsController.getAppUpdateType(manifest.name) is "required"
      updateClass     = "orange"
      updateText      = "Update Required"
      updateTooltip   = "You must update this app. Click here to see."

    @updateView.updatePartial updateText
    @updateView.setClass      updateClass
    @updateView.setTooltip    title : updateTooltip

    @experimentalView.destroy()
    @experimentalView = new KDView

  appDeleteCall:(manifest)->
    appPath   = @appsController.getAppPath manifest.path, yes
    appFolder = FSHelper.createFileInstance path: appPath, type: 'folder'
    appFolder.remove (err, res) =>

      KD.showError err,
        KodingError : "An error occured while deleting the App!"

      @deleteModal.destroy()
      @destroy()  unless err

      KD.mixpanel "Delete Application, success", manifest.name

  click:(event)->

    return if $(event.target).closest('.icon-container').length > 0 or \
              $(event.target).closest('.dev-mode').length > 0

    @showLoader()

    manifest   = @getData()
    appManager = KD.getSingleton "appManager"
    router     = KD.getSingleton "router"

    couldntCreate = =>
      appManager.off "AppCouldntBeCreated", appCreated
      @hideLoader()

    appCreated    = =>
      appManager.off "AppCreated", couldntCreate
      @hideLoader()

    appManager.once "AppCouldntBeCreated", couldntCreate
    appManager.once "AppCreated",          appCreated
    appManager.once "AppIsBeingShown", => @hideLoader()

    route = if manifest.route
      if "string" is typeof manifest.route
      then manifest.route
      else manifest.route.slug
    else "/Develop/#{manifest.name}"

    router.handleRoute route

  showLoader:->

    @loader.show()
    @img.$().css "opacity", "0.5"

  hideLoader:->

    @loader.hide()
    @img.$().css "opacity", "1"

  pistachio:->
    """
      {{> @devModeView}}
      {{> @updateView}}
      {{> @experimentalView}}
      <div class='icon-container'>
        {{> @delete}}
        {{> @info}}
        {{> @compile}}
      </div>
      {{> @loader}}
      <p>{{> @img}}</p>
      <cite>{{ #(title) or #(name) }} {{ #(version)}}</cite>
    """

class GetMoreAppsButton extends StartTabAppThumbView

  constructor:(options)->

    data =
      name        : 'Get more Apps'
      author      : 'Koding'
      description : "Get more Apps from Koding AppStore"

    super options, data

    @img.$().attr "src", "/a/images/icn-appcatalog.png"

    @compile = new KDView
    @delete = new KDView

  click : (event)->

    return if $(event.target).closest('.icon-container').length > 0
    KD.getSingleton('router').handleRoute "/Apps"


class AppShortcutButton extends StartTabAppThumbView

  constructor:(options, data)->

    if data.type is 'comingsoon'
      data.disabled = yes

    data.additionalinfo = "This is a shortcut for an internal Koding Application"

    super options, data

    @img.setAttribute "src", "/a/images/#{data.icon}"

    @compile = new KDView
    @delete  = new KDView  if data.type is 'koding-app'

  appDeleteCall:({name})->
    @showLoader()
    KD.getSingleton("kodingAppsController").removeShortcut name, (err)=>
      @deleteModal.buttons.Delete.hideLoader()
      @deleteModal.destroy()
      @hideLoader()
      unless err
        @destroy()
