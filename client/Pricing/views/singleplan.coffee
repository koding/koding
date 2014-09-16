class SinglePlanView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'single-plan', options.cssClass

    super options, data


  viewAppended : ->

    {title, cssClass, planFeatures, price, description} = @getOptions()

    normalizedPrice = price / 100

    name = title.toLowerCase()

    @addSubView new KDHeaderView
      type     : 'medium'
      cssClass : 'plan-title'
      title    : "<cite>#{normalizedPrice}</cite>MONTHLY"

    @addSubView new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'plan-summary'
      partial  : description

    @addSubView featuresContainer = new KDView
      tagName  : 'dl'
      cssClass : 'plan-features'

    for feature in planFeatures
      { cssClass, partial } = feature
      featuresContainer.addSubView new KDView
        cssClass : cssClass
        tagName  : 'dd'
        partial  : partial

    @addSubView new KDButtonView
      style     : 'plan-buy-button'
      title     : 'SELECT'
      callback  : => @emit 'PlanSelected', name, price


