_                = require 'lodash'
kd               = require 'kd'
JView            = require '../jview'
KDButtonView     = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView

module.exports = class PaymentMethodView extends JView

  constructor: (options = {}, data) ->

    options.cssClass    = kd.utils.curry "payment-method", options.cssClass
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

    @controlsView = new kd.CustomHTMLView { cssClass: 'payment-method-controls' }

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

    type = kd.utils.slugify(cardType).toLowerCase()
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
