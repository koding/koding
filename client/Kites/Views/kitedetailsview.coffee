class KiteDetailsView extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "content-page kite-details", options.cssClass

    super options, data

    @timeAgo     = new KDTimeAgoView {}, new Date @getData().createdAt
    @productForm = new KiteProductForm null, @getData()
    @productForm.on "PlanSelected", @bound "showPaymentModal"

  showPaymentModal: (plan) ->
    placeholder = new KDView cssClass: "placeholder"
    payment     = KD.singleton "paymentController"
    workflow    = payment.createUpgradeWorkflow productForm: placeholder

    workflow.on "SubscriptionTransitionCompleted", -> log ">>>>"
    workflow.on "Failed", (err) -> KD.showError err

    new KDModalView
      view     : workflow
      width    : 1000
      overlay  : yes
      cssClass : "payment-modal"

    KD.utils.defer placeholder.lazyBound "emit", "PlanSelected", plan

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
            {{> @productForm}}
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
        </div>
      </div>
    """
