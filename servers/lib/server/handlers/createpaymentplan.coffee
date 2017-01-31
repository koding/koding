{ createCustomer
  createSubscription } = require '../../../models/socialapi/requests'

{ Plan } = require '../../../../client/app/lib/redux/modules/payment/constants'

{ environment } = require 'koding-config-manager'

getDefaultTrialEnd = ->

  now = (new Date()).getTime()
  after30Days = 30 * 24 * 60 * 60 * 1000

  return Math.round (now + after30Days) / 1000


module.exports = createPaymentPlan = (params = {}, callback) ->

  # don't try to create plan for default environment
  return callback null  if environment is 'default'

  params.trialEnd ?= getDefaultTrialEnd()

  { sessionToken, source } = params

  delete params.source

  createCustomer { sessionToken, source }, (err, customer) ->
    return callback err  if err

    params.customer = customer.id
    params.plan = Plan.SOLO

    createSubscription params, (err, subscription) ->
      return callback err  if err
      return callback null
