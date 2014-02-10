class PricingPlanSelection extends JView
  constructor : (options = {}, data = {}) ->
    options.cssClass      = KD.utils.curry "plan-selection-box", options.cssClass
    options.title       or= ""
    options.description or= ""
    options.unitPrice    ?= 1
    options.hidePrice    ?= no
    options.period      or= "Month"
    super options, data

    @title    = new KDCustomHTMLView
      tagName : "h4"
      partial : "#{options.title}"

    @title.addSubView @count = new KDCustomHTMLView tagName : "cite"

    @price    = new KDCustomHTMLView
      tagName  : "h5"
      cssClass : "hidden"  if options.hidePrice
      partial  : "$#{options.slider.initialValue * options.unitPrice}/#{options.period}"

    options.slider         or= {}
    options.slider.drawBar  ?= no

    {unitPrice} = options

    @slider = new KDSliderBarView options.slider
    @slider.on "ValueChanged", (handle) =>
      value = Math.floor handle.value
      price = value * unitPrice
      @count.updatePartial if value then "#{value}x" else 'Free'
      @price.updatePartial "$#{price}/Month"
      @updateDescription value
      @emit "ValueChanged", value

    @description = new KDCustomHTMLView
      tagName    : "p"
      cssClass   : "description"
      partial    : options.description

  updateDescription:(value)->

    # return log @parent.plans


    unless @parent.plans?[value]
      @description.updatePartial @getOption 'description'
    else
      {cpu, ram, disk, totalVMs, alwaysOn} = @parent.plans[value]
      @description.updatePartial """
      <span>Resource pack contains</span>
      <cite>#{cpu}x</cite>CPU
      <cite>#{ram}x</cite>GB RAM
      <cite>#{disk}</cite>GB Disk
      <cite>#{totalVMs}x</cite>Total VMs
      <cite>#{alwaysOn}x</cite>Always on VMs
      """


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
