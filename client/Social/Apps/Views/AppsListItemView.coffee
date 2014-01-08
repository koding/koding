class AppsListItemView extends KDListItemView

  constructor:(options = {},data)->

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

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

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
