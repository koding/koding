class BillingMethodView extends JView
  constructor: (options, data) ->
    super

    @loader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : !data?
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
      address = [address1, address2].filter(Boolean).join '<br>'
      description ?= "#{cardFirstName}'s #{cardType}"
      postal = [city, state, zip].filter(Boolean).join ' '
      """
      <span class="description #{cardType.toLowerCase()}">#{description}</span>
      <span>#{cardFirstName} #{cardLastName}</span>
      <span>#{cardNumber} - #{cardMonth}/#{cardYear} (#{cardType})</span>
      #{if address then "<span>#{address}</span>" else ''}
      #{if postal then "<span>#{postal}</span>" else ''}
      """
    else "Enter billing information"

  setBillingInfo: (billingInfo) ->
    @loader.hide()
    @setData billingInfo  if billingInfo
    @billingMethodInfo.updatePartial @getCardInfoPartial billingInfo?.billing
    @billingMethodInfo.show()

  pistachio: ->
    """
    {{> @loader }}
    {{> @billingMethodInfo }}
    """

