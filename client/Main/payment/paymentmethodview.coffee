class PaymentMethodView extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "payment-method", options.cssClass
    super options, data

    @loader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : !data?

    @paymentMethodInfo = new KDCustomHTMLView cssClass  : 'billing-link'
    @paymentMethodInfo.hide()
    @setPaymentInfo data

  click: ->
    @emit "PaymentMethodChosen", @getData()

  getCardInfoPartial: (paymentMethod) ->
    return "Enter billing information"  unless paymentMethod

    { description, cardFirstName, cardLastName
      cardNumber, cardType, cardYear, cardMonth
      address1, address2, city, state, zip
    } = paymentMethod

    type = KD.utils.slugify(cardType).toLowerCase()
    @setClass type

    address      = [address1, address2].filter(Boolean).join '<br>'
    description ?= "#{cardFirstName}'s #{cardType}"
    postal       = [city, state, zip].filter(Boolean).join ' '
    cardMonth    = "0#{cardMonth}".slice(-2)
    cardYear     = "#{cardYear}".slice(-2)
    numberPrefix = if type is 'american-express' then '**** ****** *' else '**** **** **** '

    # <span class="description #{cardType.toLowerCase()}">#{description}</span>
    # #{if address then "<span>#{address}</span>" else ''}
    # #{if postal  then "<span>#{postal}</span>"  else ''}
    """
    <pre>#{numberPrefix}#{cardNumber.slice(-4)}</pre>
    <pre>#{cardFirstName} #{cardLastName}</pre>
    <pre>#{cardMonth}/#{cardYear}</pre>
    """

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
