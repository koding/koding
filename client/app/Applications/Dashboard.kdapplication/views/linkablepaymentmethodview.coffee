class LinkablePaymentMethodView extends PaymentMethodView
  viewAppended:->
    super()

    @unlinkButton = new KDButtonView
      title     : "Unlink this payment method"
      callback  : =>
        @emit 'PaymentMethodUnlinkRequested', @getData()
    @unlinkButton.hide()

    @addSubView @unlinkButton


  setPaymentInfo: (paymentMethod) ->
    super paymentMethod

    do @unlinkButton?[if paymentMethod?.billing then 'show' else 'hide']