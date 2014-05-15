ProviderInterface = require './providerinterface'

module.exports = class DigitalOcean extends ProviderInterface

  @ping = (client, options, callback)->
    callback null, "DigitalOcean is better #{ client.connection.delegate.profile.nickname }!"

  @fetchExisting = (client, options, callback)->
    callback null, []