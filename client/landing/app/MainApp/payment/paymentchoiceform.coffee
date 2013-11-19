class PaymentChoiceForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.callback = (formData) =>
      @emit 'PaymentMethodChosen', formData.paymentMethod

    options.fields ?= {}

    options.fields.intro ?=
      itemClass         : KDCustomHTMLView
      partial           : "<p>Please choose a payment method:</p>"

    options.fields.paymentMethod ?=
      itemClass         : KDCustomHTMLView
      title             : "Payment method"

    options.buttons ?= {}

    options.buttons.submit ?=
      title             : "Use <b>this</b> payment method"
      style             : "modal-clean-gray"
      type              : "submit"
      loader            :
        color           : "#ffffff"
        diameter        : 12

    options.buttons.another ?=
      title             : "Use <b>another</b> payment method"
      style             : "modal-clean-gray"
      callback          : => @emit 'PaymentMethodNotChosen'

    super options, data

  activate: (activator) -> @emit 'Activated', activator