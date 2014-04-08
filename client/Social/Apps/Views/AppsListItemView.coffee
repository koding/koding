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

    @kiteOpen = new KDButtonView
      cssClass : 'run'
      title    : 'open'
      callback : =>
        payment     = KD.singleton "paymentController"
        productForm = new KiteProductForm null, @getData()
        workflow    = payment.createUpgradeWorkflow {productForm}
        modal       = new KDModalView view: workflow
        workflow.on "SubscriptionTransitionCompleted", modal.bound "destroy"
        workflow.on "Failed", (err) -> KD.showError err

  # Override KDView::render since I'm updating all the manifest at once ~ GG
  render:-> @template.update()

  viewAppended: JView::viewAppended

  pistachio:->
    data   = @getData()
    isKite = data instanceof KD.remote.api.JKite

    {manifest:{authorNick, title}, name} = data

    template = """
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
    """

    if isKite
      @statusWidget = new KDCustomHTMLView
      template += "<div class='bottom'>{{> @kiteOpen}}</div>"
    else
      template += "<div class='bottom'>{{> @runButton}}</div>"

    return template
