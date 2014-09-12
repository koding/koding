class ResourcePackView extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "resource-pack", options.cssClass
    super options, data

  viewAppended : ->
    {title, cssClass, packFeatures, price, index, description} = @getOptions()

    price      = price / 100

    @addSubView new KDHeaderView
      type     : "medium"
      cssClass : "pack-title"
      title    : "<cite>#{price}</cite>MONTHLY"

    @addSubView new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'pack-summary'
      partial  : description

    @addSubView featuresContainer = new KDView
      tagName  : "dl"
      cssClass : "pack-features"

    for key, value of packFeatures
      featuresContainer.addSubView new KDView
        tagName : "dd"
        partial : "<em>#{value}</em> #{key}"

    @addSubView new KDButtonView
      style     : "pack-buy-button"
      title     : "SELECT"
      callback  : =>
        tag      = @getOption "tag"
        groupTag = @getDelegate().subscriptionTag
        planApi  = KD.remote.api.JResourcePlan
        @emit "PlanSelected", tag, groupTag, {planApi}, title, price
