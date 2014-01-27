class PlanUpgradeConfirmForm extends PaymentConfirmForm
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "plan-upgrade-confirm-form", options.cssClass
    super options, data
    @coupons = {}

  viewAppended: ->
    @unsetClass 'kdview'

    data = @getData()

    @plan = new KDView
      cssClass  : 'payment-confirm-plan'
      partial   :
        """
        <h3>Plan</h3>
        <p>
          #{ @getExplanation 'plan' }
        </p>
        """

    @payment = new KDView
      cssClass  : 'payment-confirm-method'
      partial   : 
        """
        <h3>Payment method</h3>
        <p>#{ @getExplanation 'payment' }</p>
        """

    super()

  getExplanation: (key) -> switch key
    when 'plan'
      "You selected this plan:"
    when 'payment'
      "This payment method will be charged:"
    else
      super key

  activate: (activator) -> @setData activator.getData()

  setData: (data) ->
    if data.productData?.plan
      {productData: {plan, planOptions}, oldSubscription} = data
      @plan.addSubView new VmPlanView {planOptions}, plan

      if plan.discountCode and plan.vmCode
        @fetchCoupons plan, ["discount", "vm"], @bound "addCouponOptions"

      if oldSubscription
        @plan.addSubView new KDView partial: "<p>Your old plan was:</p>"
        @plan.addSubView new VmPlanView {}, oldSubscription
    else
      @plan.hide()

    {paymentMethod} = data
    if paymentMethod
    then @payment.addSubView new PaymentMethodView {}, paymentMethod
    else @payment.hide()

    super data

  addCouponOptions: ->
    {discount: {discountInCents}} = @coupons

    @plan.addSubView giftWrapper = new KDCustomHTMLView cssClass: "coupon-options"
    giftWrapper.addSubView new KDLabelView title: "Select your gift"
    giftWrapper.addSubView couponOptions = new KDInputRadioGroup
      name       : "coupon-options"
      radios     : [
        title    : "#{@coupons.discount.name}"
        value    : "discount"
        callback : => @changeCouponOption "discount"
      ,
        title    : "#{@coupons.vm.name}"
        value    : "vm"
        callback : => @changeCouponOption "vm"
      ]

    couponOptions.setDefaultValue "discount"

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
    {{> @payment}}
    {{> @buttonBar}}
    """
