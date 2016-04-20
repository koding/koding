kd      = require 'kd'
remote  = require('../remote').getInstance()
globals = require 'globals'


module.exports = class PaymentController extends kd.Controller

  DEFAULT_PROVIDER = 'stripe'

  api: -> remote.api.Payment


  subscribe: (token, planTitle, planInterval, options, callback) ->

    { planAmount, binNumber, lastFour, cardName } = options

    params = {
      token, planTitle, planInterval, planAmount
      binNumber, lastFour, cardName
    }

    params.email    = options.email    if options.email
    params.provider = options.provider or DEFAULT_PROVIDER

    @api().subscribe params, (err, result) =>
      @emit 'UserPlanUpdated'  unless err?
      callback err, result


  subscribeGroup: (token, callback) ->

    params = { token }

    @api().subscribeGroup params, (err, plan) =>
      callback err, plan
      @emit 'GroupPlanUpdated'  unless err


  subscriptions: (callback) ->

    # return plan as 'koding' on default environment
    if globals.config.environment is 'default'
      # checkout servers/models/computeproviders/plans.coffee
      return callback null, { planTitle: 'koding' }

    @api().subscriptions {}, callback


  invoices: (callback) -> @api().invoices {}, callback


  creditCard: (callback) ->

    @api().creditCard {}, (err, card) ->

      card = null  if isNoCard card

      return callback err, card


  fetchGroupCreditCard: (callback) -> @api().fetchGroupCreditCard callback


  canUserPurchase: (callback) -> @api().canUserPurchase callback


  updateCreditCard: (token, callback) ->

    params          = { token }
    params.provider = DEFAULT_PROVIDER

    @api().updateCreditCard params, callback


  canChangePlan: (planTitle, callback) ->

    @api().canChangePlan { planTitle }, callback


  getPaypalToken: (planTitle, planInterval, callback) ->

    @api().getToken { planTitle, planInterval }, callback


  logOrder: (params, callback) ->

    @api().logOrder params, callback


  fetchGroupPlan: (callback) ->

    @api().fetchGroupPlan callback


  paypalReturn: (err) -> @emit 'PaypalRequestFinished', err
  paypalCancel: ->

  isNoCard = (data) ->

    return no  unless data

    noCard =
      data.last4 is '' and
      data.year  is 0 and
      data.month is 0

    return noCard
