{Gateway} = require('./gateway')
{Transaction} = require('./transaction')
{ErrorResponse} = require('./error_response')

class TransactionGateway extends Gateway
  constructor: (@gateway) ->

  create: (attributes, callback) ->
    @gateway.http.post('/transactions', {transaction: attributes}, @responseHandler(callback))

  credit: (attributes, callback) ->
    attributes.type = 'credit'
    @create(attributes, callback)

  find: (transactionId, callback) ->
    @gateway.http.get "/transactions/#{transactionId}", (err, response) ->
      if err
        callback(err, null)
      else
        callback(null, new Transaction(response.transaction))

  refund: (transactionId, amount..., callback) ->
    @gateway.http.post("/transactions/#{transactionId}/refund", {transaction: {amount: amount[0]}}, @responseHandler(callback))

  responseHandler: (callback) ->
    @createResponseHandler("transaction", Transaction, callback)

  sale: (attributes, callback) ->
    attributes.type = 'sale'
    @create(attributes, callback)

  submitForSettlement: (transactionId, amount..., callback) ->
    @gateway.http.put("/transactions/#{transactionId}/submit_for_settlement",
      {transaction: {amount: amount[0]}},
      @responseHandler(callback)
    )

  void: (transactionId, callback) ->
    @gateway.http.put("/transactions/#{transactionId}/void", null, @responseHandler(callback))

exports.TransactionGateway = TransactionGateway
