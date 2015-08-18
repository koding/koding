module.exports = class AuthedClient
  constructor:(options) ->
    { @routingKey, @socketId, @exchange } = options
