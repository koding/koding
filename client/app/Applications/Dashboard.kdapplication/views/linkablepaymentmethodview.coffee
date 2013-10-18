class LinkablePaymentMethodView extends PaymentMethodView
  viewAppended:->
    super()

    @unlinkButton = new KDButtonView
      title     : "Unlink this payment method"
      callback  : =>
        @emit 'PaymentMethodUnlinkRequested', @getData()
    @unlinkButton.hide()

    @addSubView @unlinkButton


  setPaymentInfo: (paymentInfo) ->
    super paymentInfo

    do @unlinkButton?[if paymentInfo?.billing then 'show' else 'hide']