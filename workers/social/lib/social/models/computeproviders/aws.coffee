ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

module.exports = class Aws extends ProviderInterface

  @providerSlug  = 'aws'

  @bootstrapKeys = ['key_pair', 'rtb', 'acl']

  @secretKeys = ['access_key', 'secret_key']

  @ping = (client, options, callback) ->
    callback null, "#{ @providerSlug } rulez #{ client.r.account.profile.nickname }!"

  @create = (client, options, callback) ->

    { credential, instance_type, region, image, storage_size, label } = options

    meta = {
      type          : @providerSlug
      assignedLabel : label
      region        : region ? 'us-east-1'
      instance_type : instance_type ? 't2.nano'
      storage_size  : storage_size
      image         : image
    }

    callback null, { meta, credential }

  do @_requireTemplate
