class VmPaymentConfirmForm extends PaymentConfirmForm

  viewAppended: ->
    data = @getData()

    @pack = new KDView
      cssClass  : 'payment-confirm-pack'
      partial   : 
        """
        <h2>VM</h2>
        <p>You selected this VM:</p>
        """

    @plan = new KDView
      cssClass  : 'payment-confirm-plan'
      partial   :
        """
        <h3>Plan</h3>
        <p>You'll need to upgrade your plan to create this VM.  You selected
        this plan.</p>
        """

    @subscription = new KDView
      cssClass  : 'payment-confirm-subscription'
      partial   :
        """
        <h3>Subscription</h3>
        <p>Your existing subscription will cover this purchase.</p>
        """

    @payment = new KDView
      cssClass  : 'payment-confirm-method'
      partial   : 
        """
        <h3>Payment method</h3>
        <p>This purchase will be charge to this payment method.</p>
        """

    super()

  activate: (activator) -> @setData activator.getData()

  setData: (data) ->
    throw new Error 'Product data was not provided!'  unless data.productData?

    if data.productData.pack
      packView = new VmProductView { showControls: no }, data.productData.pack
      @pack.addSubView packView
    else
      @pack.hide()

    if data.productData.subscription
      @subscription.addSubView new VmPlanView {}, data.productData.subscription
    else
      @subscription.hide()

    if data.productData.plan
      @plan.addSubView new VmPlanView {}, data.productData.plan

      if data.productData.oldSubscription?
        @plan.addSubView new KDView
          partial: "<p>Your old plan was:</p>"
        @plan.addSubView new VmPlanView {}, data.productData.oldSubscription
    else 
      @plan.hide()

    if data.paymentMethod
      @payment.addSubView new PaymentMethodView {}, data.paymentMethod
    else
      @payment.hide()

    super data

  pistachio: ->
    """
    {{> @pack}}
    {{> @plan}}
    {{> @subscription}}
    {{> @payment}}
    {{> @buttonBar}}
    """