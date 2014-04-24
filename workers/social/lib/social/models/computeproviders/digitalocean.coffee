ProviderInterface = require './providerinterface'

module.exports = class DigitalOcean extends ProviderInterface

  @ping = (client, callback)->
    callback null, "DigitalOcean is better #{ client.connection.delegate.profile.nickname }!"

  @fetchExisting = (client, callback)->
    callback null, []