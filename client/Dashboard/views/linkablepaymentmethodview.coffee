class LinkablePaymentMethodView extends PaymentMethodView
  viewAppended:->
    super()

    @linkButton = new KDButtonView
      title     : 'Link a payment method'
      callback  : =>
        @emit 'PaymentMethodEditRequested', @getData()
    @addSubView @linkButton

    @unlinkButton = new KDButtonView
      title     : "Unlink this payment method"
      callback  : =>
        @emit 'PaymentMethodUnlinkRequested', @getData()
    @unlinkButton.hide()
    @addSubView @unlinkButton

    @emit 'ready'

  setState: (state) ->
    @loader.hide()
    switch state
      when 'unlink'
        @linkButton.hide()
        @unlinkButton.show()
        @paymentMethodInfo.show()
      when 'link'
        @linkButton.show()
        @unlinkButton.hide()
        @paymentMethodInfo.hide()

  setPaymentInfo: (paymentMethod) ->
    super paymentMethod
    @ready => @setState(
      if paymentMethod?.billing
      then 'unlink'
      else 'link'
    )