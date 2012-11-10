class StartTabAppThumbView extends KDCustomHTMLView

  constructor:(options, data)->

    options.tagName    = 'figure'

    if data.disabled?
      options.cssClass += ' disabled'
    else if data.catalog?
      options.cssClass += ' appcatalog'

    super options, data

    {icns, name, version, author, description, authorNick, additionalinfo} = manifest = @getData()

    additionalinfo or= ''
    description    or= ''
    version        or= ''

    if not authorNick
      authorNick = KD.whoami().profile.nickname

    proxifyUrl=(url)->
      "https://api.koding.com/1.0/image.php?url="+ encodeURIComponent(url)

    resourceRoot = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/"

    if manifest.devMode?
      resourceRoot = "https://#{authorNick}.koding.com/.applications/#{__utils.slugify name}/"

    if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      thumb = "#{resourceRoot}/#{if icns then icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64']}"
    else
      thumb = "#{KD.apiUri + '/images/default.app.listthumb.png'}"

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
            #{additionalinfo}
          <div>
          """
      click    : -> no

    @delete = new KDView

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
    """
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

  click : (event)->

    return if $(event.target).closest('.icon-container').length > 0
    @showLoader()
    appManager.openApplication 'Apps', => @hideLoader()


class AppShortcutButton extends StartTabAppThumbView

  constructor:(options, data)->

    if data.type is 'comingsoon'
      data.disabled = yes

    data.additionalinfo = "<cite>This is a shortcut for an internal Koding Application</cite>"

    super options, data

    @img.$().attr "src", "/images/#{data.icon}"

    @compile = new KDView
    @delete  = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon delete"
      tooltip  :
        title  : "Click to delete"
      click    : =>
        @delete.hideTooltip()
        modal = new KDModalView
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
              callback   : =>
                @showLoader()
                @getSingleton("kodingAppsController").removeShortcut data.name, (err)=>
                  modal.buttons.Delete.hideLoader()
                  modal.destroy()
                  @hideLoader()
                  if not err then @destroy()

  click : (event)->

    return if $(event.target).closest('.icon-container').length > 0

    {type, name, path} = @getData()
    path = name if not path

    if type is 'koding-app'
      @showLoader()
      appManager.openApplication path, => @hideLoader()
    # else if type is 'comingsoon'
    #   new KDNotificationView
    #     title : 'Coming Soon!'
    return no
