ProviderInterface = require './providerinterface'

module.exports = class Amazon extends ProviderInterface

  @ping = (client, callback)->
    callback null, "AWS RULEZ #{ client.connection.delegate.profile.nickname }!"