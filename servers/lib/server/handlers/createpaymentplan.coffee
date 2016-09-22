{ createCustomer
  createSubscription } = require '../../../models/socialapi/requests'

{ Plan } = require '../../../../client/app/lib/redux/modules/payment/constants'

getDefaultTrialEnd = ->

  now = (new Date()).getTime()
  after30Days = 30 * 24 * 60 * 60 * 1000

  return Math.round (now + after30Days) / 1000


module.exports = createPaymentPlan = (params = {}, callback) ->

  params.trialEnd ?= getDefaultTrialEnd()

  { sessionToken } = params

  createCustomer { sessionToken }, (err, customer) ->
    return callback err  if err

    params.customer = customer.id
    params.plan = Plan.UP_TO_10_USERS

    createSubscription params, (err, subscription) ->
      return callback err  if err
      return callback null
