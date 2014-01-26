class PricingBoxWithSlider extends JView
  constructor : (options = {}, data = {}) ->
    options.cssClass    = KD.utils.curry "customize-box", options.cssClass
    options.unitName  or= "Unit"
    options.unitPrice  ?= 1
    super options, data

    @count    = new KDCustomHTMLView
      tagName : "strong"
      partial : "#{options.slider.initialValue} #{options.unitName}"

    @price    = new KDCustomHTMLView
      tagName : "span"
      partial : "$#{options.slider.initialValue * options.unitPrice}/Month"

    options.slider       or= {}
    options.slider.drawBar = no
    options.slider.width   = 307
    options.slider.handles = [options.slider.initialValue]

    @slider = new KDSliderBarView options.slider

  pistachio : ->
    """
      <span class="icon"></span>
      <div class="plan-values">
        <span class="unit-display">{{> @count }}</span>
        <span class="calculated-price">{{> @price}}</span>
      </div>
      <div class="sliderbar-outer-container">{{> @slider}}</div>
    """
