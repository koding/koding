class PaymentMethodView extends JView
  constructor: (options = {}, data) ->
    options.cssClass    = KD.utils.curry "payment-method", options.cssClass
    options.editLink   ?= no
    options.removeLink ?= no
    super options, data

    @loader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : !data?

    @editLink = new CustomLinkView
      title: ' '
      cssClass: 'edit'
      click: (e) =>
        e.preventDefault()
        @emit 'PaymentMethodEditRequested', data

    @removeLink = new CustomLinkView
      title: ' '
      cssClass: 'remove'
      click: (e) =>
        e.preventDefault()
        @emit 'PaymentMethodRemoveRequested', data

    if @getOption 'editLink' or @getOption 'removeLink'
    then @controlsView = new KDCustomHTMLView cssClass : 'payment-method-controls'
    else @controlsView = new KDCustomHTMLView tagName  : 'span'

    if @getOption 'editLink'   then @controlsView.addSubView @editLink
    if @getOption 'removeLink' then @controlsView.addSubView @removeLink

    @paymentMethodInfo = new KDCustomHTMLView cssClass  : 'billing-link'
    @paymentMethodInfo.hide()
    @setPaymentInfo data

  click: ->
    @emit "PaymentMethodChosen", @getData()

  getCardInfoPartial: (paymentMethod) ->
    return "Enter billing information"  unless paymentMethod

    {  cardNumber, cardType } = paymentMethod

    type = KD.utils.slugify(cardType).toLowerCase()
    @setClass type

    # address      = [address1, address2].filter(Boolean).join '<br>'
    # description ?= "#{cardFirstName}'s #{cardType}"
    # postal       = [city, state, zip].filter(Boolean).join ' '
    # cardMonth    = "0#{cardMonth}".slice(-2)
    # cardYear     = "#{cardYear}".slice(-2)
    numberPrefix = if type is 'american-express' then '**** ****** *' else '**** **** **** '

    # <span class="description #{cardType.toLowerCase()}">#{description}</span>
    # #{if address then "<span>#{address}</span>" else ''}
    # #{if postal  then "<span>#{postal}</span>"  else ''}
    """
    <div class='card-type'>#{cardType}</div>
    <pre>#{numberPrefix}#{cardNumber.slice(-4)}</pre>
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
    {{> @controlsView }}
    """
