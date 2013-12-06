class PlanUpgradeConfirmForm extends PaymentConfirmForm

  viewAppended: ->
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
      @plan.addSubView new VmPlanView {}, data.productData.plan

      if data.oldSubscription?
        @plan.addSubView new KDView
          partial: "<p>Your old plan was:</p>"
        @plan.addSubView new VmPlanView {}, data.oldSubscription
    else 
      @plan.hide()

    if data.paymentMethod
      @payment.addSubView new PaymentMethodView {}, data.paymentMethod
    else
      @payment.hide()

    super data

  pistachio: ->
    """
    {{> @plan}}
    {{> @payment}}
    {{> @buttonBar}}
    """