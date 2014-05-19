ProviderInterface = require './providerinterface'

module.exports = class EngineYard extends ProviderInterface

  @ping = (client, callback)->
    callback null, "EngineYard is cool #{ client.connection.delegate.profile.nickname }!"
