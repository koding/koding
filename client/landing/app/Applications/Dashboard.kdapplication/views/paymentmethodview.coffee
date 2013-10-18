class PaymentMethodView extends JView
  constructor: (options, data) ->
    super

    @loader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : !data?
      cssClass    : 'fr'

    @paymentMethodInfo = new KDCustomHTMLView
      tagName   : 'a'
      cssClass  : 'billing-link'
      click     : (e) =>
        e.preventDefault()
        @emit 'PaymentMethodEditRequested'

    @paymentMethodInfo.hide()

    @setPaymentInfo data

  getCardInfoPartial: (paymentInfo) ->
    if paymentInfo
      { description, cardFirstName, cardLastName, cardNumber, cardMonth
        cardYear, cardType, address1, address2, city, state, zip } = paymentInfo
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

  setPaymentInfo: (paymentInfo) ->
    @loader.hide()
    @setData paymentInfo  if paymentInfo
    @paymentMethodInfo.updatePartial @getCardInfoPartial paymentInfo?.billing
    @paymentMethodInfo.show()

  pistachio: ->
    """
    {{> @loader }}
    {{> @paymentMethodInfo }}
    """

