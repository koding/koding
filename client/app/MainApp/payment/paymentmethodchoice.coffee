class PaymentMethodChoiceView extends JView

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry 'billing-method-choice', options.cssClass

    super options, data

  viewAppended: ->
    @methods = new KDView

    @createNewMethodButton = new KDButtonView
      title     : 'Use another billing method'
      callback  : => @emit 'PaymentMethodSelected'

    super()

  addPaymentMethod:(paymentMethod) ->
    paymentMethodView = new PaymentMethodView {}, paymentMethod

    @methods.addSubView paymentMethodView

    paymentMethodView.on 'PaymentMethodEditRequested', =>
      @emit 'PaymentMethodSelected', paymentMethod.paymentMethodId

  pistachio:->
    """
    <div>Please link an existing billing method:</div>
    {div{> @methods }}
    {div{> @createNewMethodButton }}</div
    """
