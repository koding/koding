{Gateway} = require('./gateway')
{CreditCard} = require('./credit_card')

class CreditCardGateway extends Gateway
  constructor: (@gateway) ->

  create: (attributes, callback) ->
    @gateway.http.post('/payment_methods', {creditCard: attributes}, @responseHandler(callback))

  delete: (token, callback) ->
    @gateway.http.delete("/payment_methods/#{token}", callback)

  find: (token, callback) ->
    @gateway.http.get "/payment_methods/#{token}", (err, response) ->
      if err
        callback(err, null)
      else
        callback(null, new CreditCard(response.creditCard))

  update: (token, attributes, callback) ->
    @gateway.http.put("/payment_methods/#{token}", {creditCard: attributes}, @responseHandler(callback))

  responseHandler: (callback) ->
    @createResponseHandler("creditCard", CreditCard, callback)

exports.CreditCardGateway = CreditCardGateway
