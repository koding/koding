kd = require 'kd'

module.exports = isPlanFree = (callback) ->

  kd.singletons.paymentController.subscriptions (err, subscription) ->
    return callback err  if err
    callback null, subscription.planTitle is 'free'

