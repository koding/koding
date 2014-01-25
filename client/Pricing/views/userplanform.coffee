class UserPlanForm extends JView
  constructor: (options = {}, data) ->
    options.cssClass    = KD.utils.curry "user-plan-form", options.cssClass
    options.unitPrice or= 1
    super options, data

    @choice = 1

  viewAppended: ->
    {unitPrice} = @getOptions()
    @multiplier = new KDCustomHTMLView
      cssClass  : "multiplier"
      partial   : "X1"

    @price      = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "price"
      partial   : "$#{unitPrice}"

    @buyNow     = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "buy-now"
      partial   : "BUY NOW"
      click     : =>
        KD.remote.api.JPaymentPlan.one tags: $in: ["rp#{@choice}"], (err, plan) =>
          @emit "PlanSelected", plan

    @resourcePackSlider = new KDSliderBarView
      cssClass   : "resource-pack-selection"
      minValue   : 1
      maxValue   : 5
      interval   : 1
      snap       : yes
      snapOnDrag : yes
      drawBar    : yes
      showLabels : no
      handles    : [1]

    @resourcePackSlider.on "ValueChanged", (handle) =>
      @choice = handle.getSnappedValue()
      @multiplier.updatePartial "X#{@choice}"
      @price.updatePartial "$#{@choice * unitPrice}"

    super

  pistachio: ->
    """
    <h1>SIMPLE YET POWERFUL PRICING</h1>
    <div class="resource-pack-selection">
      <div class="top">
        <div class="left">
          <span class="description">RESOURCE PACK</span>
        </div>
        <div class="right">
          {{> @price}}<span class="unit">/Month</span>
          {{> @buyNow}}
        </div>
        {{> @multiplier}}
      </div>
      <div class="bottom">
        {{> @resourcePackSlider}}
        <div class="reward">
          <span class="title">REWARD</span>
          <span class="detail">+$4 OFF OR 1 SHARED VM</span>
        </div>
      </div>
    </div>
    """
