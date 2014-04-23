class PricingPlanSelection extends JView
  constructor : (options = {}, data = {}) ->
    options.cssClass      = KD.utils.curry "plan-selection-box", options.cssClass
    options.title        ?= ""
    options.description  ?= ""
    options.unitPrice    ?= 1
    options.hidePrice    ?= no
    options.period       ?= "Month"
    options.amountSuffix ?= ""
    super options, data

    @title    = new KDCustomHTMLView
      tagName : "h4"
      partial : "#{options.title}"

    @price     = new KDCustomHTMLView
      tagName  : "h5"
      cssClass : if options.hidePrice then "hidden"
      partial  : "$#{options.slider.initialValue * options.unitPrice}/#{options.period}"

    options.slider            or= {}
    options.slider.drawBar    ?= no

    {unitPrice} = options

    @slider = new KDSliderBarView options.slider
    @slider.on "ValueChanged", (handle) =>
      value = Math.floor handle.value
      price = value * unitPrice
      @price.updatePartial "$#{price}/Month"
      @emit "ValueChanged", value

  viewAppended: ->
    super
    @unsetClass "kdview"

  pistachio: ->
    """
    {{> @title}}
    {{> @slider}}
    """
