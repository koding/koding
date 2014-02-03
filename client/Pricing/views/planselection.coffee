class PricingPlanSelection extends JView
  constructor : (options = {}, data = {}) ->
    options.cssClass      = KD.utils.curry "plan-selection-box", options.cssClass
    options.title       or= ""
    options.description or= ""
    options.unitPrice    ?= 1
    options.period      or= "Month"
    super options, data

    @title    = new KDCustomHTMLView
      tagName : "h4"
      partial : "#{options.title}"

    @title.addSubView @count = new KDCustomHTMLView tagName : "cite"

    @price    = new KDCustomHTMLView
      tagName : "h5"
      partial : "$#{options.slider.initialValue * options.unitPrice}/#{options.period}"

    options.slider       or= {}
    options.slider.drawBar = no
    options.slider.handles = [options.slider.initialValue]

    {unitPrice} = options

    @slider = new KDSliderBarView options.slider
    @slider.on "ValueChanged", (handle) =>
      value = handle.getSnappedValue()
      price = value * unitPrice
      @count.updatePartial "#{value}x"
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

    # """
    #   <span class="icon"></span>
    #   <div class="plan-values">
    #     <span class="unit-display">{{> @count }}</span>
    #     <span class="calculated-price">{{> @price}}</span>
    #   </div>
    #   <div class="sliderbar-outer-container">{{> @slider}}</div>
    # """
