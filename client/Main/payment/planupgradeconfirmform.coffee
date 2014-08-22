class PlanUpgradeConfirmForm extends PaymentConfirmForm
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "plan-upgrade-confirm-form", options.cssClass
    super options, data
    @coupons = {}

    @buttonBar = new KDButtonBar
      buttons       :
        Buy         :
          title     : "PLACE YOUR ORDER"
          style     : "solid medium green"
          loader    : yes
          callback  : =>
            @buttonBar.buttons['Buy'].showLoader()
            @emit 'PaymentConfirmed'
        cancel      :
          title     : "CANCEL"
          style     : "solid medium light-gray"
          cssClass  : 'to-left'
          callback  : => @emit 'Cancel'

  viewAppended: ->
    @unsetClass 'kdview'

    data = @getData()

    @plan = new KDView
      partial   :
        """
          <h3 class="pricing-title">#{ @getExplanation 'plan' }</h3>
          <h6 class="pricing-subtitle">Almost there, review your purchase and get going</h6>
        """
    super()

  getExplanation: (key) -> switch key
    when 'plan'
      "You selected this plan"
    when 'payment'
      "This payment method will be charged"
    else
      super key

  activate: (activator) -> @setData activator.getData()

  setData: (data) ->
    if data.productData?.plan
      {productData: {plan, planOptions}, oldSubscription} = data

      if oldSubscription
        @plan.addSubView new KDCustomHTMLView
          tagName : 'h6'
          cssClass: 'mini-title'
          partial : 'Your current plan'

        @plan.addSubView new GenericPlanView {cssClass:"old-plan"}, oldSubscription.plan

        @plan.addSubView new KDCustomHTMLView
          tagName : 'h6'
          cssClass: 'mini-title'
          partial : 'Upgrading to'

      @plan.addSubView new GenericPlanView {planOptions}, plan

      {couponCodes} = plan

      if couponCodes and couponCodes.discount and couponCodes.vm
        @plan.addSubView @giftWrapper = new KDCustomHTMLView cssClass: "coupon-options clearfix hidden"
        @giftWrapper.addSubView new KDLabelView
          title: "Select your gift"
          cssClass: "select-gift"

        @fetchCoupons plan, ["discount", "vm"], @bound "addCouponOptions"

    else
      @plan.hide()

    super data

  addCouponOptions: ->
    return  unless Object.keys(@coupons).length
    {discount: {discountInCents}} = @coupons

    @giftWrapper.show()

    @giftWrapper.addSubView couponOptions = new KDInputRadioGroup
      name       : "coupon-options"
      radios     : [
        title    : "#{@coupons.discount.name}"
        value    : "discount"
      ,
        title    : "#{@coupons.vm.name}"
        value    : "vm"
      ]

    couponOptions.on "change", @bound "changeCouponOption"

    @plan.addSubView totalWrapper = new KDCustomHTMLView cssClass: "total-wrapper"

    totalWrapper.addSubView discount = new KDCustomHTMLView cssClass: "discount"
    discount.addSubView new KDLabelView title: "Discount"
    discount.addSubView @discount = new KDCustomHTMLView
      tagName  : "span"
      partial  : @utils.formatMoney discountInCents / 100

    totalWrapper.addSubView subtotal = new KDCustomHTMLView cssClass: "subtotal"
    subtotal.addSubView new KDLabelView title: "Subtotal"
    subtotal.addSubView @subtotal = new KDCustomHTMLView
      tagName  : "span"
      partial  : (@getData().productData.plan.feeAmount - @utils.formatMoney discountInCents) / 100

    couponOptions.setDefaultValue "discount"
    @changeCouponOption "discount"

    @updateTotals couponOptions.getValue()

  changeCouponOption: (name) ->
    @emit "CouponOptionChanged", name
    @updateTotals name

  updateTotals: (code) ->
    {discountType, discountInCents} = @coupons[code]
    switch discountType
      when "dollars"
        @discount.updatePartial @utils.formatMoney discountInCents / 100
        @subtotal.updatePartial @utils.formatMoney (@getData().productData.plan.feeAmount - discountInCents) / 100

  fetchCoupons: (plan, codes, callback) ->
    {dash} = Bongo
    queue = codes.map (code) =>
      =>
        plan.fetchCoupon code, (err, coupon) =>
          return  if KD.showError err
          @coupons[code] = coupon
          queue.fin()
    dash queue, callback

  pistachio: ->
    """
    {{> @plan}}
    {{> @buttonBar}}
    """
