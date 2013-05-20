class StartTabAppThumbView extends KDCustomHTMLView

  constructor:(options, data)->

    options.tagName    = 'figure'

    if data.disabled?
      options.cssClass += ' disabled'
    else if data.catalog?
      options.cssClass += ' appcatalog'

    super options, data

    {icns, name, version, author, description,
     authorNick, additionalinfo} = manifest = @getData()

    additionalinfo or= ''
    description    or= ''
    version        or= ''

    if not authorNick
      authorNick = KD.whoami().profile.nickname

    proxifyUrl=(url)->
      KD.config.mainUri + '/-/imageProxy?url=' + encodeURIComponent(url)

    resourceRoot = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/"

    if manifest.devMode
      resourceRoot = "https://#{authorNick}.koding.com/.applications/#{__utils.slugify name}/"

    thumb = "#{KD.apiUri + '/images/default.app.thumb.png'}"

    for size in [512, 256, 160, 128, 64]
      if icns and icns[String size]
        thumb = "#{resourceRoot}/#{icns[String size]}"
        break

    if location.hostname is "localhost"
      thumb = "/images/default.app.thumb.png"

    @img = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @img.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : thumb

    @loader = new KDLoaderView
      size          :
        width       : 40

    @info = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon info"
      tooltip  :
        offset :
          top  : 4
          left : -5
        title  : """
          <div class='app-tip'>
            <header><strong>#{name} #{version}</strong> <cite>by #{author}</cite></header>
            <p class='app-desc'>#{description.slice(0,200)}#{if description.length > 199 then '...' else ''}</p>
            #{additionalinfo}
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
          title          : "Delete App"
          content        : "<div class='modalformline'>Are you sure you want to delete this app?</div>"
          height         : "auto"
          overlay        : yes
          buttons        :
            Delete       :
              style      : "modal-clean-red"
              loader     :
                color    : "#ffffff"
                diameter : 16
              callback   : => @appDeleteCall manifest

    if @getData().devMode
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
          @getSingleton("kodingAppsController").compileApp \
            manifest.name, (err)=>
              @hideLoader()
          no

      @devModeView = new KDCustomHTMLView
        partial  : "Dev Mode"
        cssClass : "dev-mode"
        tooltip  :
          title  : "Dev-Mode enabled, click for help."
        click    : =>
          new KDModalView
            overlay  : yes
            width    : 500
            title    : "Dev Mode"
            content  : __utils.expandUrls """<div class='modalformline'><p>
                          If you set <code>devMode</code> to <code>true</code>
                          in the <code>.manifest</code> file, you can compile
                          this app on the Koding Application servers. When you
                          compile your app, shared resources like stylesheets
                          or images in your app will be served from
                          #{resourceRoot} </p></div>"""
    else
      @compile     = new KDView
      @devModeView = new KDView

  appDeleteCall:(manifest)->
    apps      = @getSingleton("kodingAppsController")
    appPath   = apps.getAppPath manifest.path, yes
    appFolder = FSHelper.createFileFromPath appPath, 'folder'
    appFolder.remove (err, res) =>
      unless err
        apps.refreshApps =>
          @deleteModal.destroy()
          @destroy()
        , no
      else
        new KDNotificationView
          title    : "An error occured while deleting the App!"
          type     : 'mini'
          cssClass : 'error'
        @deleteModal.destroy()

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

  click:(event)->

    return if $(event.target).closest('.icon-container').length > 0 or \
              $(event.target).closest('.dev-mode').length > 0
    manifest = @getData()
    @showLoader()
    @getSingleton("kodingAppsController").runApp manifest, => @hideLoader()

  showLoader:->

    @loader.show()
    @img.$().css "opacity", "0.5"

  hideLoader:->

    @loader.hide()
    @img.$().css "opacity", "1"

  pistachio:->
    """
      {{> @devModeView}}
      <div class='icon-container'>
        {{> @delete}}
        {{> @info}}
        {{> @compile}}
      </div>
      {{> @loader}}
      <p>{{> @img}}</p>
      <cite>{{ #(name)}} {{ #(version)}}</cite>
    """

class GetMoreAppsButton extends StartTabAppThumbView

  constructor:(options)->

    data =
      name        : 'Get more Apps'
      author      : 'Koding'
      description : "Get more Apps from Koding AppStore"

    super options, data

    @img.$().attr "src", "/images/icn-appcatalog.png"

    @compile = new KDView
    @delete = new KDView

  click : (event)->

    return if $(event.target).closest('.icon-container').length > 0
    @showLoader()
    KD.getSingleton("appManager").open 'Apps', => @hideLoader()


class AppShortcutButton extends StartTabAppThumbView

  constructor:(options, data)->

    if data.type is 'comingsoon'
      data.disabled = yes

    data.additionalinfo = "<cite>This is a shortcut for an internal Koding Application</cite>"

    super options, data

    @img.$().attr "src", "/images/#{data.icon}"

    @compile = new KDView

  appDeleteCall:({name})->
    @showLoader()
    @getSingleton("kodingAppsController").removeShortcut name, (err)=>
      @deleteModal.buttons.Delete.hideLoader()
      @deleteModal.destroy()
      @hideLoader()
      if not err then @destroy()

  click:(event)->

    return if $(event.target).closest('.icon-container').length > 0

    {type, name, path} = @getData()
    path = name if not path

    if type is 'koding-app'
      @showLoader()
      KD.getSingleton("appManager").open path, => @hideLoader()

    return no
