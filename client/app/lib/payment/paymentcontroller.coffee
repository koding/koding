sinkrow = require 'sinkrow'
$ = require 'jquery'
getGroup = require '../util/getGroup'
remote = require('../remote').getInstance()
whoami = require '../util/whoami'
showError = require '../util/showError'
kd = require 'kd'


module.exports = class PaymentController extends kd.Controller

  DEFAULT_PROVIDER = 'stripe'

  api: -> remote.api.Payment


  subscribe: (token, planTitle, planInterval, options, callback) ->

    {planAmount, binNumber, lastFour, cardName} = options

    params = {
      token, planTitle, planInterval, planAmount
      binNumber, lastFour, cardName
    }

    params.email    = options.email    if options.email
    params.provider = options.provider or DEFAULT_PROVIDER

    @api().subscribe params, (err, result) =>
      @emit 'UserPlanUpdated'  unless err?
      callback err, result


  subscriptions : (callback) -> @api().subscriptions {}, callback
  invoices      : (callback) -> @api().invoices {}, callback


  creditCard: (callback) ->

    @api().creditCard {}, (err, card) ->

      card = null  if isNoCard card

      return callback err, card


  canUserPurchase: (callback) -> @api().canUserPurchase callback


  updateCreditCard: (token, callback) ->

    params          = {token}
    params.provider = DEFAULT_PROVIDER

    @api().updateCreditCard params, callback


  canChangePlan: (planTitle, callback) ->

    @api().canChangePlan {planTitle}, callback


  getPaypalToken: (planTitle, planInterval, callback) ->

    @api().getToken {planTitle, planInterval}, callback


  logOrder: (params, callback) ->

    @api().logOrder params, callback


  paypalReturn: (err) -> @emit 'PaypalRequestFinished', err
  paypalCancel: ->

  isNoCard = (data) ->

    return no  unless data

    noCard =
      data.last4 is '' and
      data.year  is 0 and
      data.month is 0

    return noCard
