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

    { last4, brand } = paymentMethod

    type = kd.utils.slugify(brand).toLowerCase()

    prefix = 'ending with '

    """
    <cite class='icon #{type}'></cite>
    <span class='credit-card-title'>#{prefix}#{last4}</span>
    """


  updatePaymentMethod: (paymentMethod) ->

    return @data = null  if @isNoCard paymentMethod

    @data = _.assign {}, paymentMethod


  setPaymentInfo: (paymentMethod) ->

    @updatePaymentMethod paymentMethod
    @updateViewStates paymentMethod
    @paymentMethodInfo.show()

  pistachio: ->
    """
    {{> @paymentMethodInfo }}
    {{> @controlsView }}
    """
