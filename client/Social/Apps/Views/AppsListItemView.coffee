class AppsListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.type = "appstore"

    super options, data

    @thumbnail = new KDView
      cssClass : 'thumbnail'
      partial  : "<span class='logo'>#{data.name[0]}</span>"

    @thumbnail.setCss 'backgroundColor', KD.utils.getColorFromString data.name

    @runButton = new KDButtonView
      cssClass : 'run'
      title    : 'run'
      callback : =>
        KodingAppsController.runExternalApp @getData()
        KD.mixpanel "App run, click"

    @statusWidget = new KDView
      cssClass : KD.utils.curry 'status-widget', data.status
      tooltip  : title : {
        'github-verified': "Public"
        'not-verified'   : "Private"
        'verified'       : "Verified"
      }[data.status]

  # Override KDView::render since I'm updating all the manifest at once ~ GG
  render:-> @template.update()

  viewAppended: JView::viewAppended

  pistachio:->

    {manifest:{authorNick, title}, name} = @getData()

    """
      <figure>
        {{> @thumbnail}}
      </figure>
      {{> @statusWidget}}
      <div class="appmeta clearfix">
        <a href="/Apps/#{authorNick}/#{name}">
          <h3>#{title or name}</h3>
          <cite></cite>
        </a>
        <h4>{{#(manifest.author)}}</h4>
        <div class="appdetails">
          <article>{{@utils.shortenText #(manifest.description)}}</article>
        </div>
      </div>
      <div class='bottom'>
        {{> @runButton}}
      </div>
    """
