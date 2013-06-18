class OpenWithModalItem extends JView

  constructor: (options= {}, data) ->

    options.cssClass = "app"

    super options, data

    {authorNick, name, version, icns} = manifest = @getData()

    resourceRoot = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/"

    if manifest.devMode
      resourceRoot = "https://#{authorNick}.koding.com/.applications/#{__utils.slugify name}/"

    image  = if name is "Ace" then "icn-ace" else "default.app.thumb"
    thumb  = "#{KD.apiUri}/images/#{image}.png"

    for size in [64, 128, 160, 256, 512]
      if icns and icns[String size]
        thumb = "#{resourceRoot}/#{icns[String size]}"
        break

    @img = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @img.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : thumb

    @setClass "not-supported" unless @getOptions().supported

    @on "click", =>
      delegate = @getDelegate()
      delegate.selectedApp.unsetClass "selected" if delegate.selectedApp
      @setClass "selected"
      delegate.selectedApp = @

  pistachio: ->
    """
      {{> @img}}
      <div class="app-name">#{@getData().name}</div>
    """
