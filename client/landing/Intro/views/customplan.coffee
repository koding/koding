class CustomPlan extends JView
  unitPrices     =
    user         : 5
    resourcePack : 20

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "custom-plan", options.cssClass
    super options, data

    @users           = new PricingBoxWithSlider
      cssClass       : "users"
      unitPrice      : unitPrices.user
      unitName       : "Users"
      slider         :
        minValue     : 1
        maxValue     : 100
        initialValue : 10
        interval     : 5

    @resources       = new PricingBoxWithSlider
      cssClass       : "resources"
      unitPrice      : unitPrices.resourcePack
      unitName       : "Resources"
      slider         :
        minValue     : 1
        maxValue     : 100
        initialValue : 10
        interval     : 5

    @price     = new KDCustomHTMLView tagName: "span"
    @promotion = new KDCustomHTMLView cssClass: "promotion"

    @buyNow    = new KDButtonView
      cssClass : "solid buy-now"
      title    : "BUY NOW"

  pistachio: ->
    """
    {{> @users}}
    <span class="plus-icon"></span>
    {{> @resources}}
    <span class="equal-icon"></span>
    <div class="summary">
      <div class="plan-top">
        <h2>Custom Plan</h2>
        <div class="price">
          <cite>$</cite>{{> @price}}<span class="period">/MONTH</span>
        </div>
      </div>
      <div>
        {{> @buyNow}}
        {{> @promotion}}
      </div>
    </div>
    """
