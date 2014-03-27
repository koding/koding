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
        kite = @getData()
        kite.fetchPlans (err, plans)->
          return KD.showError err if err
          user = KD.whoami()
          user.fetchPaymentMethods (err, paymentMethods)->
            return KD.showError err if err
            {paymentMethodId} = paymentMethods.first
            # TODO: THAT IS FOR TESTING PURPOSES
            # NEED TO CHANGE BEFORE MERGE
            plans.first.subscribe paymentMethodId, {},(err, subscription)->
              log subscription

          log plans.first


  # Override KDView::render since I'm updating all the manifest at once ~ GG
  render:-> @template.update()

  viewAppended: JView::viewAppended

  pistachio:->
    unless @getData() instanceof KD.remote.api.JKite
      {manifest:{authorNick}, name} = @getData()

      """
        <figure>
          {{> @thumbnail}}
        </figure>
        {{> @statusWidget}}
        <div class="appmeta clearfix">
          <a href="/Apps/#{authorNick}/#{name}">
            <h3>#{name}</h3>
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
    else
      {name, description} = @getData()
      """
        <figure>
          {{> @thumbnail}}
        </figure>
        <div class="appmeta clearfix">
          <h3>#{name}</h3>
          <cite></cite>
          <div class="appdetails">
            <article>#{description}</article>
          </div>
        </div>
        <div class='bottom'>
          {{> @kiteOpen}}
        </div>
      """
