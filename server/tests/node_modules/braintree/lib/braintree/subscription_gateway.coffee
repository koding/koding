{Gateway} = require('./gateway')
{Subscription} = require('./subscription')
{TransactionGateway} = require('./transaction_gateway')

class SubscriptionGateway extends Gateway
  constructor: (@gateway) ->

  create: (attributes, callback) ->
    @gateway.http.post('/subscriptions', {subscription: attributes}, @responseHandler(callback))

  cancel: (subscriptionId, callback) ->
    @gateway.http.put("/subscriptions/#{subscriptionId}/cancel", null, @responseHandler(callback))

  find: (subscriptionId, callback) ->
    @gateway.http.get "/subscriptions/#{subscriptionId}", (err, response) ->
      if err
        callback(err, null)
      else
        callback(null, new Subscription(response.subscription))

  responseHandler: (callback) ->
    @createResponseHandler("subscription", Subscription, callback)

  retryCharge: (subscriptionId, amount..., callback) ->
    new TransactionGateway(@gateway).sale
      amount: amount[0],
      subscriptionId: subscriptionId
    , callback

  update: (subscriptionId, attributes, callback) ->
    @gateway.http.put("/subscriptions/#{subscriptionId}", {subscription: attributes}, @responseHandler(callback))

exports.SubscriptionGateway = SubscriptionGateway
