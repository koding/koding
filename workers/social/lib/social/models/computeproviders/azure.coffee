ProviderInterface = require './providerinterface'

module.exports = class Azure extends ProviderInterface

  @ping = (client, callback) ->
    callback null, "Azure is cool #{ client.connection.delegate.profile.nickname }!"
