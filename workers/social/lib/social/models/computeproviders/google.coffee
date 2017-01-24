ProviderInterface = require './providerinterface'

module.exports = class Google extends ProviderInterface

  @providerSlug  = 'google'

  @bootstrapKeys = ['koding_network_id']

  @secretKeys    = ['credentials']

  @ping = (client, callback) ->
    callback null, "Google. #{ client.connection.delegate.profile.nickname }!"

  @create = (client, options, callback) ->

    { credential, instance_type, region, image, storage_size, label } = options

    meta = {
      type          : @providerSlug
      assignedLabel : label
      region        : region ? 'us-central1-a'
      instance_type : instance_type ? 'f1-micro'
      storage_size  : storage_size ? 8
      image         : image
    }

    callback null, { meta }

  do @_requireTemplate
