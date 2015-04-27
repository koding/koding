kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDHeaderView = kd.HeaderView
KDView = kd.View
trackEvent = require 'app/util/trackEvent'


module.exports = class SinglePlanView extends KDView

  getInitialState: -> {
    planInterval: 'year'
  }

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'single-plan', options.cssClass

    super options, data

    @state = kd.utils.extend @getInitialState(), options.state

    @initViews()


  initViews: ->

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
        <cite>#{if price is '0' then 'Free' else price}</cite>
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
      state     : { title, monthPrice, yearPrice }
      callback  : @bound 'select'


  select: ->

    { title, monthPrice, yearPrice
      reducedMonth, discount } = @getOptions()

    { planInterval } = @state

    planTitle = title.toLowerCase()

    @emit 'PlanSelected', {
      planTitle, monthPrice, yearPrice
      reducedMonth, discount, planInterval
    }

    trackEvent 'Plan select, click', {
      category : 'userInteraction'
      action   : 'clicks'
      label    : 'PricingSelect'
      planInterval
      planTitle
    }


  setPlanInterval: (planInterval) ->

    kd.utils.extend @state, { planInterval }

    price = @getPrice planInterval

    price = if price is '0'
    then 'Free'
    else price

    @price.updatePartial "
      <cite>#{(price)}</cite>
      <span class='interval-text'>MONTHLY</span>
    "


  getPrice: (planInterval) ->

    priceMap =
      month : @getOption 'monthPrice'
      year  : @getOption 'reducedMonth'

    return price = priceMap[planInterval]


  disable: (isCurrent = yes) ->

    @setClass 'current'  if isCurrent
    @buyButton.disable()

    @setAttribute 'disabled', 'disabled'


  enable: ->

    @unsetClass 'current'
    @buyButton.enable()

    @setAttribute 'disabled', 'false'

