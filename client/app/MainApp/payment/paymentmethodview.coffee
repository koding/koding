class PaymentMethodView extends JView
  constructor: (options, data) ->
    super

    @loader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : !data?
      cssClass    : 'fr'

    @paymentMethodInfo = new KDCustomHTMLView
      cssClass  : 'billing-link'

    @paymentMethodInfo.hide()

    @setPaymentInfo data

  getCardInfoPartial: (paymentMethod) ->
    if paymentMethod
      { description, cardFirstName, cardLastName, cardNumber, cardMonth
        cardYear, cardType, address1, address2, city, state, zip } = paymentMethod
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

  setPaymentInfo: (paymentMethod) ->
    @loader.hide()
    @setData paymentMethod  if paymentMethod
    @paymentMethodInfo.updatePartial @getCardInfoPartial paymentMethod?.billing
    @paymentMethodInfo.show()

  pistachio: ->
    """
    {{> @loader }}
    {{> @paymentMethodInfo }}
    """

