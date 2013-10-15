class LinkableBillingMethodView extends BillingMethodView
  viewAppended:->
    super()

    @unlinkButton = new KDButtonView
      title     : "Unlink this payment method"
      callback  : =>
        @emit 'PaymentMethodUnlinkRequested', @getData()
    @unlinkButton.hide()

    @addSubView @unlinkButton


  setBillingInfo: (billingInfo) ->
    super billingInfo

    do @unlinkButton?[if billingInfo?.billing then 'show' else 'hide']