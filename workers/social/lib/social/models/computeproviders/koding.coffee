
ProviderInterface = require './providerinterface'
KodingError       = require '../../error'
JVM               = require '../vm'

module.exports = class Koding extends ProviderInterface

  @ping = (client, callback)->

    callback null, "Koding is the best #{ client.connection.delegate.profile.nickname }!"


  @fetchExisting = (client, options, callback)->

    JVM.fetchVmsByContext client, options, callback


  @create = (client, options, callback)->

    {nonce, stackId} = options
    JVM.createVmByNonce client, nonce, stackId, callback


  @remove = (client, options, callback)->

    {hostnameAlias} = options
    JVM.removeByHostname client, hostnameAlias, callback


  @update = (client, options, callback)->

    callback new KodingError \
      "Update not supported for Koding VMs", "NotSupported"


  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "small"
        title : "Small 1x"
        spec  : {
          cpu : 1, ram: 1, storage: 4
        }
        price : 'free'
      }
      {
        name  : "large"
        title : "Large 2x"
        spec  : {
          cpu : 2, ram: 2, storage: 8
        }
      }
      {
        name  : "extra-large"
        title : "Extra Large 4x"
        spec  : {
          cpu : 4, ram: 4, storage: 16
        }
      }
    ]