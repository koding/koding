class AppsListItemView extends KDListItemView

  constructor:(options = {},data)->

    options.type = "appstore"

    super options,data

    {icns, name, version, authorNick} = @getData().manifest
    if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      thumb = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/#{if icns then icns['160'] or icns['128'] or icns['256'] or icns['512'] or icns['64']}"
    else
      thumb = "#{KD.apiUri + '/images/default.app.listthumb.png'}"

    @thumbnail = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumbnail.$().attr "src", "/images/default.app.listthumb.png"
      attributes  :
        src       : thumb

  click:(event)->
    event.stopPropagation()
    event.preventDefault()
    list = @getDelegate()
    app  = @getData()
    list.emit "AppWantsToExpand", app

  viewAppended:->

    @setClass "waits-approve" if not @getData().approved

    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <figure>
      {{> @thumbnail}}
    </figure>
    <div class="appmeta clearfix">
      <h3>{a[href="#"]{#(title)}}</h3>
      <div class="appstats">
        <p class="installs">
          <span class="icon"></span>
          <a href="#">{{#(counts.installed) || 0}}</a> Installs
        </p>
        <p class="followers">
          <span class="icon"></span>
          <a href="#">{{#(counts.followers) || 0}}</a> Followers
        </p>
      </div>
    </div>
    <div class="appdetails">
      <h3>{a[href="#"]{#(title)}}</h3>
      <article>{{@utils.shortenText #(body)}}</article>
      <a href="#">Application Page →</a>
    </div>
    """
