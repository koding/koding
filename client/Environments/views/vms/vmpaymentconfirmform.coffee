class VmPaymentConfirmForm extends PlanUpgradeConfirmForm

  viewAppended: ->
    data = @getData()

    @pack = new KDView
      cssClass  : 'payment-confirm-pack'
      partial   :
        """
        <h2>#{ @getExplanation 'pack' }</h2>
        """

    @subscription = new KDView
      cssClass  : 'payment-confirm-subscription'
      partial   :
        """
        <h3>Subscription</h3>
        <p>#{ @getExplanation 'subscription' }</p>
        """

    super()

  getExplanation: (key) -> switch key
    when 'pack'
      "You selected this VM:"
    when 'plan'
      "You'll need to upgrade your plan for this purchase:"
    when 'subscription'
      "Your existing subscription will cover this purchase."
    else
      super key

  setData: (data) ->
    super data

    throw new Error 'Product data was not provided!'  unless data.productData?

    if data.productData.pack
      packView = new VmProductItemView { showControls: no }, data.productData.pack
      @pack.addSubView packView
    else
      @pack.hide()

    if data.productData.subscription
      @subscription.addSubView new GenericPlanView {hiddenPrice : yes}, data.productData.subscription.plan
    else
      @subscription.hide()


  pistachio: ->
    """
    {{> @pack}}
    {{> @plan}}
    {{> @subscription}}
    {{> @buttonBar}}
    """
