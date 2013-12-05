class AppsListItemView extends KDListItemView

  constructor:(options = {},data)->

    options.type = "appstore"

    super options,data

    {icns, identifier, version, authorNick} = @getData().manifest
    if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      thumb = "#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{if icns then icns['160'] or icns['128'] or icns['256'] or icns['512'] or icns['64']}"
    else
      thumb = "#{KD.apiUri + '/images/default.app.listthumb.png'}"

    @thumbnail = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      attributes  :
        src       : thumb

    @thumbnail.off 'error'
    @thumbnail.on  'error', ->
      @setAttribute "src", "/images/default.app.listthumb.png"

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
      <h3>{a[href="#"]{#(name)}}</h3>
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
      <article>{{@utils.shortenText #(manifest.description)}}</article>
      <a href="/#{@getData().slug}">Application Page →</a>
    </div>
    """
