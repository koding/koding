class IntroPlanSelection extends JView
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

    @title.addSubView @count = new KDCustomHTMLView tagName : "cite"

    @price     = new KDCustomHTMLView
      tagName  : "h5"
      cssClass : "hidden"  if options.hidePrice
      partial  : "$#{options.slider.initialValue * options.unitPrice}/#{options.period}"

    options.slider         or= {}
    options.slider.drawBar  ?= yes

    {unitPrice} = options

    @slider = new KDSliderBarView options.slider
    @slider.on "ValueChanged", (handle) =>
      value = Math.floor handle.value
      price = value * unitPrice
      @count.updatePartial if value then "#{value}#{options.amountSuffix}" else 'Free'
      @price.updatePartial "$#{price}/Month"
      @emit "ValueChanged", value

    @description = new KDCustomHTMLView
      tagName    : "p"
      cssClass   : "description"
      partial    : options.description

  viewAppended: ->
    super
    @unsetClass "kdview"

  pistachio: ->
    """
    {{> @title}}
    {{> @price}}
    {{> @slider}}
    {{> @description}}
    """
