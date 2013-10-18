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

  addPaymentMethod:(paymentInfo) ->
    paymentMethodView = new PaymentMethodView {}, paymentInfo

    @methods.addSubView paymentMethodView

    paymentMethodView.on 'PaymentMethodEditRequested', =>
      @emit 'PaymentMethodSelected', paymentInfo.paymentMethodId

  pistachio:->
    """
    <div>Please link an existing billing method:</div>
    {div{> @methods }}
    {div{> @createNewMethodButton }}</div
    """
