ProviderInterface = require './providerinterface'

module.exports = class DigitalOcean extends ProviderInterface

  @providerSlug  = 'digitalocean'

  @bootstrapKeys = ['key_id', 'key_name', 'key_fingerprint']

  @secretKeys    = ['access_token']

  @ping = (client, options, callback) ->

    callback null, "DigitalOcean is better #{ client.r.account.profile.nickname }!"

  @create = (client, options, callback) ->

    { credential, instance_type, region, image, storage_size, label } = options

    meta = {
      type          : @providerSlug
      assignedLabel : label
      region        : region ? 'nyc2'
      instance_type : instance_type ? '512mb'
      storage_size  : storage_size ? 20
      image         : image ? 'ubuntu-14-04-x64'
    }

    callback null, { meta, credential }

  do @_requireTemplate
