class LinkablePaymentMethodView extends PaymentMethodView

  viewAppended:->
    super()

    @linkButton = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "payment-links link"
      partial   : "Link a payment method"
      click     : =>
        @emit 'PaymentMethodEditRequested', @getData()

    @addSubView @linkButton

    @unlinkButton = new KDCustomHTMLView
      tagName     : "span"
      cssClass    : "payment-links unlink"
      partial     : "Unlink this payment method"
      click       : =>
        @emit 'PaymentMethodUnlinkRequested', @getData()

    @unlinkButton.hide()
    @addSubView @unlinkButton

    @emit 'ready'

  setState: (state) ->
    @loader.hide()
    switch state
      when 'unlink'
        @parent.setClass "linked"
        @linkButton.hide()
        @unlinkButton.show()
        @paymentMethodInfo.show()
      when 'link'
        @parent.unsetClass "linked"
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