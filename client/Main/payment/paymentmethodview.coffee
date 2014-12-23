class PaymentMethodView extends JView

  constructor: (options = {}, data) ->

    options.cssClass    = KD.utils.curry "payment-method", options.cssClass
    options.editLink   ?= no
    options.removeLink ?= no

    super options, data

    @createViews()


  updateViewStates: (method) ->

    @paymentMethodInfo.updatePartial @getCardInfoPartial method

    if method
    then @controlsView.show()
    else @controlsView.hide()


  isNoCard: (data) ->

    return  unless data

    noCard =
      data.last4 is '' and
      data.year  is 0 and
      data.month is 0

    return noCard


  createViews: ->

    data = @getData()

    @editLink = new KDButtonView
      title    : 'Update'
      cssClass : 'edit solid medium gray'
      callback : (e) =>
        e.preventDefault()
        @emit 'PaymentMethodEditRequested', data

    @removeLink = new KDButtonView
      title    : 'Remove'
      cssClass : 'remove'
      click    : (e) =>
        e.preventDefault()
        @emit 'PaymentMethodRemoveRequested', data

    if @getOption 'editLink' or @getOption 'removeLink'
    then @controlsView = new KDCustomHTMLView cssClass : 'payment-method-controls hidden'
    else @controlsView = new KDCustomHTMLView tagName  : 'span'

    if @getOption 'editLink'   then @controlsView.addSubView @editLink
    if @getOption 'removeLink' then @controlsView.addSubView @removeLink

    @paymentMethodInfo = new KDCustomHTMLView cssClass : 'billing-link'
    @paymentMethodInfo.hide()
    @setPaymentInfo data


  getCardInfoPartial: (paymentMethod) ->

    noCardPartial = "<span class='no-item-found'>You have no payment methods</span>"

    return noCardPartial  if not paymentMethod or @isNoCard paymentMethod

    { last4 } = paymentMethod

    # TODO: we need to get the
    # card type info with the payload, but for now
    # let's just use visa, and don't show it anywhere. ~U
    cardType = 'visa'

    type = KD.utils.slugify(cardType).toLowerCase()
    @setClass type

    numberPrefix = if type is 'american-express'
    then '**** ****** *'
    else '**** **** **** '

    """
    <pre>#{numberPrefix}#{last4}</pre>
    """


  updatePaymentMethod: (paymentMethod) ->

    return @data = null  if @isNoCard paymentMethod

    @data[key] = value  for key, value of paymentMethod


  setPaymentInfo: (paymentMethod) ->

    @updatePaymentMethod paymentMethod
    @updateViewStates paymentMethod
    @paymentMethodInfo.show()

  pistachio: ->
    """
    {{> @paymentMethodInfo }}
    {{> @controlsView }}
    """
