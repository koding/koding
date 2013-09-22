class BillingMethodView extends JView
  constructor: (options, data) ->
    super

    appManager  = KD.getSingleton 'appManager'
    group       = @getData()

    @loader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : yes
      cssClass    : 'fr'

    @billingMethodInfo = new KDCustomHTMLView
      tagName   : 'a'
      cssClass  : 'billing-link'
      click     : =>
        @loader.show()
        appManager.tell(
          'Dashboard' , 'showBillingInfoModal'
          'group'     , group
          => @loader.hide()
        )

    appManager.tell 'Dashboard', 'fetchBillingInfo', group, (err, billing) =>
      cardInfo =
        unless err
          """
          <p>#{billing.cardFirstName} #{billing.cardLastName}</p>
          <p>#{billing.cardNumber} - #{billing.cardMonth}/#{billing.cardYear} (#{billing.cardType})</p>
          <p>#{billing.address1} #{billing.address2}</p>
          <p>#{billing.city} #{billing.state} #{billing.zip}</p>
          """
        else "Enter billing information"

      @setBillingInfo cardInfo

    @billingMethodInfo.hide()

  setBillingInfo: (billingInfo) ->
    @loader.hide()
    @billingMethodInfo.updatePartial billingInfo
    @billingMethodInfo.show()

  pistachio: ->
    """
    {{> @loader }}
    {{> @billingMethodInfo }}
    """

