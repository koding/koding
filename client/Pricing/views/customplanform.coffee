class CustomPlanForm extends JView
  constructor: (options = {}, data) ->
    options.cssClass            = KD.utils.curry "custom-plan-form", options.cssClass
    options.userUnitPrice     or= 1
    options.resourceUnitPrice or= 1
    super options, data

    {userUnitPrice, resourceUnitPrice} = options

    @userQuantity     = 1
    @resourceQuantity = 1
    @total            = (@userQuantity * userUnitPrice) + (@resourceQuantity * resourceUnitPrice)

    @totalPrice = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "total"
      partial   : KD.utils.formatMoney @total

    @userCount  = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "user-count"
      partial   : "#{@userQuantity}"

    @userPrice  = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "user-price"
      partial   : KD.utils.formatMoney userUnitPrice

    @userCountSlider = new KDSliderBarView
      cssClass       : "user-count-slider"
      minValue       : 1
      maxValue       : 100
      interval       : 1
      snap           : yes
      snapOnDrag     : yes
      drawBar        : yes
      showLabels     : no
      handles        : [1]

    @userCountSlider.on "ValueChanged", (handle) =>
      value = handle.getSnappedValue()
      @userQuantity = value
      @userCount.updatePartial value
      @userPrice.updatePartial KD.utils.formatMoney value * userUnitPrice

    @resourceCount       = new KDCustomHTMLView
      tagName            : "span"
      cssClass           : "resource-count"
      partial            : "#{@resourceQuantity}"

    @resourcePrice       = new KDCustomHTMLView
      tagName            : "span"
      cssClass           : "resource-price"
      partial            : KD.utils.formatMoney resourceUnitPrice

    @resourceCountSlider = new KDSliderBarView
      cssClass           : "resource-count-slider"
      minValue           : 1
      maxValue           : 100
      interval           : 1
      snap               : yes
      snapOnDrag         : yes
      drawBar            : yes
      showLabels         : no
      handles            : [1]

    @resourceCountSlider.on "ValueChanged", (handle) =>
      value = handle.getSnappedValue()
      @resourceQuantity = value
      @resourceCount.updatePartial value
      @resourcePrice.updatePartial KD.utils.formatMoney value * resourceUnitPrice

    @userCountSlider.on "ValueChanged", @bound "updateTotal"
    @resourceCountSlider.on "ValueChanged", @bound "updateTotal"

    @buyNow = new KDButtonView
      title    : "BUY NOW"
      callback : =>
        KD.remote.api.JPaymentPlan.one tags: ["custom-plan"], (err, plan) =>
          @emit "PlanSelected", plan, {
            @userQuantity
            @resourceQuantity
            total: @total * 100
          }

  updateTotal: ->
    {userUnitPrice, resourceUnitPrice} = @getOptions()
    @total = (@userQuantity * userUnitPrice) + (@resourceQuantity * resourceUnitPrice)
    @totalPrice.updatePartial KD.utils.formatMoney @total

  pistachio: ->
    """
    <div class="left">
      <div class="users">
        <div class="heading">
          <span class="icon"></span>
          <span class="count">{{> @userCount}} x USER</span>
        </div>
        <div class="total">
          <span class="price">{{> @userPrice}}/m</span>
        </div>
        {{> @userCountSlider}}
      </div>
      <div class="resources">
        <div class="heading">
          <span class="icon"></span>
          <span class="count">{{> @resourceCount}} x RESOURCE PACK</span>
        </div>
        <div class="total">
          <span class="price">{{> @resourcePrice}}/m</span>
        </div>
        {{> @resourceCountSlider}}
      </div>
    </div>
    <div class="right">
      <h1>Small business</h1>
      <span class="price">{{> @totalPrice}}/m</span>
      {{> @buyNow}}
    </div>
    """
