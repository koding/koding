class PaymentChoiceForm extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "pricing-payment-choice clearfix", options.cssClass
    super options, data

  activate: (activator) -> @emit 'Activated', activator

  setPaymentMethods: (paymentMethods) ->
    { preferredPaymentMethod, methods, appStorage } = paymentMethods
    for method in methods
      @addSubView view = new PaymentMethodView null, method
      @forwardEvent view, "PaymentMethodChosen"

    @addSubView new KDCustomHTMLView
      cssClass : "new-payment-method"
      partial  : "+"
      click    : @lazyBound "emit", "PaymentMethodNotChosen"

    return this

  viewAppended: ->
    @addSubView new KDCustomHTMLView
      tagName: "h3"
      partial: "Choose a payment method"

    @addSubView new KDCustomHTMLView
      tagName: "h6"
      partial: "Or add a new one, whatever works"
