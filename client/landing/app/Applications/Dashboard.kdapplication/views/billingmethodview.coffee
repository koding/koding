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
      click     : (e) =>
        e.preventDefault()
        @emit 'BillingEditRequested'

    @billingMethodInfo.hide()

    @setBillingInfo data

  getCardInfoPartial: (billingInfo) ->
    if billingInfo
      { description, cardFirstName, cardLastName, cardNumber, cardMonth
        cardYear, cardType, address1, address2, city, state, zip } = billingInfo
      address = [address1, address2].filter(Boolean).join ' '
      description ?= "#{cardFirstName}'s #{cardType}"
      """
      <span class="description #{cardType.toLowerCase()}">#{description}</span>
      <span>#{cardFirstName} #{cardLastName}</span>
      <span>#{cardNumber} - #{cardMonth}/#{cardYear} (#{cardType})</span>
      <span>#{address}</span>
      <span>#{city} #{state} #{zip}</span>
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

