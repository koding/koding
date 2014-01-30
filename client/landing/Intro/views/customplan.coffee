class IntroCustomPlan extends JView
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

    @userQuantity     = 10
    @resourceQuantity = 10

    @users.on "ValueChanged", (quantity) =>
      @userQuantity = quantity
      @usersPrice = quantity * unitPrices.user
      @updatePrice @usersPrice + @resourcesPrice

    @resources.on "ValueChanged", (quantity) =>
      @resourceQuantity = quantity
      @resourcesPrice = quantity * unitPrices.resourcePack
      @updatePrice @resourcesPrice + @usersPrice

    @usersPrice     = 50
    @resourcesPrice = 200
    @updatePrice @usersPrice + @resourcesPrice

    @buyNow    = new KDButtonView
      cssClass : "solid buy-now"
      title    : "BUY NOW"
      callback : =>
        appManager = KD.singleton "appManager"
        appManager.open "Pricing", (app) =>
          KD.singleton("router").handleRoute "/Pricing/Enterprise", suppressListeners: yes
          app.selectPlan "custom-plan", {
            @userQuantity
            @resourceQuantity
            planApi: KD.remote.api.JGroupPlan
            total: (@usersPrice + @resourcesPrice) * 100
          }

  updatePrice: (price) ->
    @price.updatePartial price

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
