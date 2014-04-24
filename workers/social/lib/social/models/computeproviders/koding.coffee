ProviderInterface = require './providerinterface'

module.exports = class Koding extends ProviderInterface

  @ping = (client, callback)->

    callback null, "Koding is the best #{ client.connection.delegate.profile.nickname }!"


  @fetchExisting = (client, options, callback)->

    JVM = require '../vm'
    JVM.fetchVmsByContext client, options, callback

    console.log options.credential