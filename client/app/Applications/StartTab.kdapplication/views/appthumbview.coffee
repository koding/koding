class StartTabAppThumbView extends KDCustomHTMLView

  constructor:(options, data)->

    options.tagName    = 'figure'

    if data.disabled?
      options.cssClass += ' disabled'
    else if data.catalog?
      options.cssClass += ' appcatalog'

    super options, data

    {icns, name, version, author, description, authorNick} = manifest = @getData()

    if not authorNick
      authorNick = KD.whoami().profile.nickname

    if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      thumb = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/#{if icns then icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64']}"
    else
      thumb = "#{KD.apiUri + '/images/default.app.listthumb.png'}"

    @img = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        # @img.$().attr "src", "#{KD.apiUri + '/images/default.app.listthumb.png'}"
        @img.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : thumb

    @loader = new KDLoaderView
      size          :
        width       : 40

    @compile = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon compile"
      tooltip  :
        title  : "Click to compile"
      click    : =>
        @showLoader()
        delete KDApps[manifest.name]
        @getSingleton("kodingAppsController").getAppScript manifest, =>
          @hideLoader()
          new KDNotificationView type : "mini", title : "App Compiled"
        no

    @info = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon info"
      tooltip  :
        title  : """
          <div class='app-tip'>
            <header><strong>#{name} #{version}</strong> <cite>by #{author}</cite></header>
            <p class='app-desc'>#{description.slice(0,200)}#{if description.length > 199 then '...' else ''}</p>
          <div>
          """
      click    : -> no

    # @delete = new KDCustomHTMLView
    #   tagName  : "span"
    #   cssClass : "icon delete"
    #   tooltip  :
    #     title  : "Click to delete"
    #   click    : -> no

    @setClass "dev-mode" if @getData().devMode

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

  click : (event)->

    return if $(event.target).closest('.icon-container').length > 0
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
    # {{> @delete}}
    """
      <div class='icon-container'>
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
      version     : ''
      author      : 'Koding'
      description : "Get more Apps from Koding AppStore"

    super options, data

    @img.$().attr "src", "/images/icn-appcatalog.png"

    @compile = new KDView

  click : (event)->

    return if $(event.target).closest('.icon-container').length > 0
    @showLoader()
    appManager.openApplication 'Apps', => @hideLoader()
