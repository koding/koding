class PaymentChoiceForm extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "pricing-payment-choice clearfix", options.cssClass
    options.name     = 'method'

    super options, data


  activate: (activator) -> @emit 'Activated', activator


  setPaymentMethods: (paymentMethods) ->

    @paymentMethodsContainer.addSubView new KDButtonView
      cssClass  : 'add-big-btn'
      title     : 'Add new payment method'
      icon      : yes
      callback  : @lazyBound "emit", "PaymentMethodNotChosen"

    { preferredPaymentMethod, methods, appStorage } = paymentMethods
    for method in methods
      @paymentMethodsContainer.addSubView view = new PaymentMethodView null, method
      @forwardEvent view, "PaymentMethodChosen"

    return this


  viewAppended: ->

    @addSubView new KDCustomHTMLView
      tagName  : "h3"
      cssClass : "pricing-title"
      partial  : "Choose a payment method"

    @addSubView new KDCustomHTMLView
      tagName  : "h6"
      cssClass : "pricing-subtitle"
      partial  : "Click on one of your credit cards to use it or add a new one"

    @addSubView @paymentMethodsContainer = new KDCustomHTMLView
      cssClass  : "payment-methods"
