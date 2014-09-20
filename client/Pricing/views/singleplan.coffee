class SinglePlanView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'single-plan', options.cssClass

    super options, data


  viewAppended : ->

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

    @addSubView @overflowVisible = new KDCustomHTMLView
      cssClass : 'overflow-visible'

    @addSubView @overflowHidden = new KDCustomHTMLView
      cssClass : 'overflow-hidden'

    @overflowVisible.addSubView new KDCustomHTMLView
      cssClass : 'plan-title'
      partial  : title.toUpperCase()

    @overflowHidden.addSubView new KDHeaderView
      type     : 'medium'
      cssClass : 'plan-price'
      title    : "<cite>#{monthPrice / 100}</cite>MONTHLY"

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
        @emit 'PlanSelected', {
          planTitle, monthPrice, yearPrice, reducedMonth, discount
        }


  disable: ->
    @setClass 'current'
    @buyButton.disable()


  enable: ->
    @unsetClass 'current'
    @buyButton.enable()


