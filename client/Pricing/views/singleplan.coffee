class SinglePlanView extends KDView

  initialState: {
    planInterval: 'year'
  }

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'single-plan', options.cssClass

    super options, data

    @state = @utils.extend @initialState, options.state


  viewAppended: ->

    {
      title
      cssClass
      planFeatures
      monthPrice
      yearPrice
      reducedMonth
      discount
      description
    } = @getOptions()

    { planInterval } = @state

    @addSubView @overflowVisible = new KDCustomHTMLView
      cssClass : 'overflow-visible'

    @addSubView @overflowHidden = new KDCustomHTMLView
      cssClass : 'overflow-hidden'

    @overflowVisible.addSubView new KDCustomHTMLView
      cssClass : 'plan-title'
      partial  : title.toUpperCase()

    price = @getPrice planInterval

    @price = new KDHeaderView
      type     : 'medium'
      cssClass : 'plan-price'
      title    : "
        <cite>#{(price / 100) or 'Free'}</cite>
        <span class='interval-text'>MONTHLY</span>
      "

    @overflowHidden.addSubView @price

    @overflowHidden.addSubView new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'plan-summary'
      partial  : description

    @overflowHidden.addSubView featuresContainer = new KDView
      tagName  : 'dl'
      cssClass : 'plan-features'

    for feature in planFeatures
      { cssClass, partial } = feature
      featuresContainer.addSubView new KDView
        cssClass : cssClass
        tagName  : 'dd'
        partial  : partial

    @addSubView @buyButton = new KDButtonView
      style     : 'plan-buy-button'
      title     : 'SELECT'
      state     : { name, monthPrice, yearPrice }
      callback  : =>
        { title, monthPrice, yearPrice } = @getOptions()
        planTitle = title.toLowerCase()

        { planInterval } = @state

        @emit 'PlanSelected', {
          planTitle, monthPrice, yearPrice
          reducedMonth, discount, planInterval
        }


  setPlanInterval: (planInterval) ->

    price = @getPrice planInterval

    @price.updatePartial "
      <cite>#{(price / 100) or 'Free'}</cite>
      <span class='interval-text'>MONTHLY</span>
    "


  getPrice: (planInterval) ->

    priceMap =
      month : @getOption 'monthPrice'
      year  : @getOption 'reducedMonth'

    return price = priceMap[planInterval]


  disable: ->
    @setClass 'current'
    @buyButton.disable()


  enable: ->
    @unsetClass 'current'
    @buyButton.enable()


