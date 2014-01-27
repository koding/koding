class PaymentChoiceForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.cssClass = "pricing-payment-choice clearfix"

    options.callback = (formData) =>
      @emit 'PaymentMethodChosen', formData.paymentMethod

    options.fields ?= {}

    options.fields.intro ?=
      itemClass         : KDCustomHTMLView
      tagName           : "h3"
      partial           : "Choose a payment method"

    options.fields.subTitle ?=
      itemClass         : KDCustomHTMLView
      tagName           : "h6"
      partial           : "Or add a new one, whatever works"

    options.fields.paymentMethod ?=
      itemClass         : KDCustomHTMLView
      title             : "Payment methods"

    # options.buttons ?= {}

    # options.buttons.submit ?=
    #   title             : "Use <b>this</b> payment method"
    #   style             : "modal-clean-gray"
    #   type              : "submit"
    #   loader            :
    #     color           : "#ffffff"
    #     diameter        : 12

    # options.buttons.another ?=
    #   title             : "Use <b>another</b> payment method"
    #   style             : "modal-clean-gray"
    #   callback          : => @emit 'PaymentMethodNotChosen'

    super options, data

  activate: (activator) -> @emit 'Activated', activator

  setPaymentMethods: (paymentMethods) ->

    { preferredPaymentMethod, methods, appStorage } = paymentMethods

    paymentField = @fields['Payment methods']

    switch methods.length

      when 0 then break

      when 1 then do ([method] = methods) =>
        paymentField.addSubView new PaymentMethodView {}, method
        @addCustomData 'paymentMethod', method

      else

        methodsByPaymentMethodId =
          methods.reduce( (acc, method) ->
            acc[method.paymentMethodId] = method
            acc
          , {})

        defaultPaymentMethod = preferredPaymentMethod ? methods[0].paymentMethodId

        defaultMethod = methodsByPaymentMethodId[defaultPaymentMethod]

        @addCustomData 'paymentMethod', defaultMethod

        # select = new KDSelectBox
        #   defaultValue  : defaultPaymentMethod
        #   name          : 'paymentMethodId'
        #   selectOptions : methods.map (method) ->
        #     title       : KD.utils.getPaymentMethodTitle method
        #     value       : method.paymentMethodId
        #   callback      : (paymentMethodId) =>
        #     chosenMethod = methodsByPaymentMethodId[paymentMethodId]
        #     @addCustomData 'paymentMethod', chosenMethod

        # paymentField.addSubView select

    return this
