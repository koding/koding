class KitesAppController extends AppController

  KD.registerAppClass this,
    name            : "Kites"
    route           : "/:name?/Kites?/:username?/:kite?"
    enforceLogin    : yes
    hiddenHandle    : yes
    searchRoute     : "/Kites?q=:text:"
    behaviour       : 'application'
    version         : "1.0"

  constructor:(options = {}, data)->
    options.appInfo =
      name          : "Kites"
      type          : "applications"

    super options, data

  handleQuery: (query) ->
    {currentPath} = KD.getSingleton "router"

    # an example full query is "/Kites/fatihacet/MyKite"
    # so temp = "/", route = "Kites", username = "fatihacet", kiteName = "MyKite"
    [temp, route, username, kiteName] = currentPath.split "/"

    if (not username and not kiteName) or (username and not kiteName)
      return @goToKites()

    @displayKiteContent username, kiteName

  goToKites: ->
    KD.getSingleton("router").handleRoute "/Apps?filter=kites"

  displayKiteContent: (username, kiteName) ->
    query =
      "manifest.name"       : kiteName
      "manifest.authorNick" : username

    KD.remote.api.JKite.list query, {}, (err, kite) =>
      return KD.showError err  if err

      unless kite.length
        new KDNotificationView
          type     : "mini"
          cssClass : "error"
          title    : "There is no kite named #{kiteName}"
          duration : 4000

        return @goToKites()

      $("body").addClass "apps"
      @getView().addSubView new KiteDetailsView {}, kite.first


class KiteDetailsView extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "content-page kite-details", options.cssClass

    super options, data

    @timeAgo    = new KDTimeAgoView {}, new Date @getData().createdAt
    @button     = new KDButtonView
      title     : "SUBSCRIBE"
      cssClass  : "run"

    @pricing    = new KDView
    payment     = KD.singleton "paymentController"
    productForm = new KiteProductForm null, @getData()
    workflow    = payment.createUpgradeWorkflow { productForm }

    @pricing.addSubView workflow

    workflow.on "SubscriptionTransitionCompleted", -> log ">>>>"
    workflow.on "Failed", (err) -> KD.showError err

  pistachio: ->
    {name, createdAt, manifest:{description, author, authorNick, readme}} = @getData()

    """
      <div class="kdview kdscrollview">
        <div class="kdview app-logo" style="background-color:#{KD.utils.getColorFromString name}">
          <span class="logo">#{name[0]}</span>
        </div>
        <div class="app-info">
          <h3><a href="#">#{name}</a></h3>
          <h4>#{author}</h4>
          <div class="appdetails">
            <article>#{description}</article>
          </div>
        </div>
        <div class="kdview app-extras pricing">
          <div class="kdview readme has-markdown">
            <h2>Pricing</h2>
            {{> @pricing}}
          </div>
        </div>
        <div class="kdview app-extras">
          <div class="kdview readme has-markdown">
            #{KD.utils.applyMarkdown readme}
          </div>
        </div>
        <div class="installerbar">
          <div class="versionstats updateddate">
            Version 0.1
            <p>Released {{> @timeAgo}}</p>
          </div>
          <div class="action-buttons">
            {{> @button}}
          </div>
        </div>
      </div>
    """
