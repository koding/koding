class ResourcePackView extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "resource-pack", options.cssClass
    super options, data

  selectPlan: ->
    return  unless subscriptionTag = @getDelegate().subscriptionTag
    KD.singletons.paymentController.fetchActiveSubscription [subscriptionTag], (err, subscription) =>
      return KD.showError err  if err
      @emit "CurrentSubscriptionSet", subscription  if subscription
      @emit "PlanSelected", @getOption("tag"), planApi: KD.remote.api.JResourcePlan

  viewAppended : ->
    {title, cssClass, packFeatures, price, index} = @getOptions()

    @addSubView new KDHeaderView
      type     : "medium"
      cssClass : "pack-title"
      title    : "<cite>#{title}</cite> Resource Pack"

    @addSubView featuresContainer = new KDView
      tagName  : "dl"
      cssClass : "pack-features"

    for key, value of packFeatures
      featuresContainer.addSubView new KDView
        tagName : "dd"
        partial : "<em>#{value}</em> #{key}"

    @addSubView new KDButtonView
      style     : "pack-buy-button"
      icon      : yes
      title     : "<cite>#{price}</cite>BUY NOW"
      callback  : @bound "selectPlan"
