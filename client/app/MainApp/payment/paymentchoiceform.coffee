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

  setPaymentMethods: (paymentMethods) ->

    { preferredPaymentMethod, methods, appStorage } = paymentMethods

    paymentField = @fields['Payment method']

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

        choiceForm.addCustomData 'paymentMethod', defaultMethod

        select = new KDSelectBox
          defaultValue  : defaultPaymentMethod
          name          : 'paymentMethodId'
          selectOptions : methods.map (method) ->
            title       : KD.utils.getPaymentMethodTitle method
            value       : method.paymentMethodId
          callback      : (paymentMethodId) ->
            chosenMethod = methodsByPaymentMethodId[paymentMethodId]
            choiceForm.addCustomData 'paymentMethod', chosenMethod

        paymentField.addSubView select

    return this
