ProviderInterface = require './providerinterface'

module.exports = class Azure extends ProviderInterface

  @providerSlug  = 'azure'

  @bootstrapKeys = ['subnet', 'hosted_service_name', 'address_space']

  @sensitiveKeys = ['publish_settings']


  @ping = (client, callback) ->
    callback null, "Azure is cool #{ client.connection.delegate.profile.nickname }!"


  @create = (client, options, callback) ->

    { credential, instance_type, region, image, storage_size, label } = options

    meta =
      type          : @providerSlug
      assignedLabel : label
      region        : region ? 'East US 2'
      instance_type : instance_type ? 'Basic_A1'
      storage_size  : storage_size
      image         : image

    callback null, { meta, credential }
