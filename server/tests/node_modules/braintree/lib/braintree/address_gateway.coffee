{Gateway} = require('./gateway')
{Address} = require('./address')

class AddressGateway extends Gateway
  constructor: (@gateway) ->

  create: (attributes, callback) ->
    customerId = attributes.customerId
    delete(attributes.customerId)
    @gateway.http.post("/customers/#{customerId}/addresses", {address: attributes}, @responseHandler(callback))

  delete: (customerId, id, callback) ->
    @gateway.http.delete("/customers/#{customerId}/addresses/#{id}", callback)

  find: (customerId, id, callback) ->
    @gateway.http.get "/customers/#{customerId}/addresses/#{id}", (err, response) ->
      if err
        callback(err, null)
      else
        callback(null, response.address)

  update: (customerId, id, attributes, callback) ->
    @gateway.http.put("/customers/#{customerId}/addresses/#{id}", {address: attributes}, @responseHandler(callback))

  responseHandler: (callback) ->
    @createResponseHandler("address", Address, callback)

exports.AddressGateway = AddressGateway
