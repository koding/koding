class BillingMethodView extends JView
  constructor: (options, data) ->
    super

    appManager  = KD.getSingleton 'appManager'
    group       = @getData()

    @loader = new KDLoaderView
      size        : { width: 14 }
      cssClass    : 'fr'

    @billingMethodInfo = new KDCustomHTMLView
      tagName   : 'a'
      cssClass  : 'billing-link'
      click     : => @emit 'BillingEditRequested'

    @billingMethodInfo.hide()

    @setBillingInfo data

  getCardInfoPartial: (billingInfo) ->
    if billingInfo
      { cardFirstName, cardLastName, cardNumber, cardMonth, cardYear
      cardType, address1, address2, city, state, zip } = billingInfo
      """
      <p>#{cardFirstName} #{cardLastName}</p>
      <p>#{cardNumber} - #{cardMonth}/#{cardYear} (#{cardType})</p>
      <p>#{address1} #{address2}</p>
      <p>#{city} #{state} #{zip}</p>
      """
    else "Enter billing information"

  setBillingInfo: (billingInfo) ->
    @loader.hide()
    @billingMethodInfo.updatePartial @getCardInfoPartial billingInfo
    @billingMethodInfo.show()

  pistachio: ->
    """
    {{> @loader }}
    {{> @billingMethodInfo }}
    """

