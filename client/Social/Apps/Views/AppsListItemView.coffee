class AppsListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.type = "appstore"

    super options, data

    @thumbnail = new KDView
      cssClass : 'thumbnail'
      partial  : "<span class='logo'>#{data.name[0]}</span>"

    @thumbnail.setCss 'backgroundColor', KD.utils.getColorFromString data.name
    @setClass "waits-approve"  unless @getData().approved

    @runButton = new KDButtonView
      cssClass : 'run'
      title    : 'run'
      callback : =>
        KodingAppsController.runExternalApp @getData()
        KD.mixpanel "App run, click"

  # Override KDView::render since I'm updating all the manifest at once ~ GG
  render:-> @template.update()

  viewAppended: JView::viewAppended

  pistachio:->
    """
      <figure>
        {{> @thumbnail}}
      </figure>
      <div class="appmeta clearfix">
        <h3><a href="/#{@getData().slug}">#{@getData().name}</a></h3>
        <h4>{{#(manifest.author)}}</h4>
        <div class="appdetails">
          <article>{{@utils.shortenText #(manifest.description)}}</article>
        </div>
      </div>
      <div class='bottom'>
        {{> @runButton}}
      </div>
    """
