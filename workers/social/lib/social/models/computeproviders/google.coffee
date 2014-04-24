ProviderInterface = require './providerinterface'

module.exports = class Google extends ProviderInterface

  @ping = (client, callback)->
    callback null, "Google. #{ client.connection.delegate.profile.nickname }!"