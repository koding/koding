ProviderInterface = require './providerinterface'

module.exports = class Aws extends ProviderInterface

  @providerSlug  = 'aws'

  @bootstrapKeys = ['key_pair', 'rtb', 'acl']

  @sensitiveKeys = ['access_key', 'secret_key']


  @ping = (client, options, callback) ->
    callback null, "#{ @providerSlug } rulez #{ client.r.account.profile.nickname }!"


  @create = (client, options, callback) ->

    { credential, instanceType, region, ami, storage } = options

    storage ?= 8
    if isNaN storage
      return callback new KodingError \
      'Requested storage size is not valid.', 'WrongParameter'

    meta =
      type          : @providerSlug
      region        : region ? 'us-east-1'
      instance_type : instanceType ? 't2.micro'
      storage_size  : storage

    if ami?
      meta.source_ami = ami

    callback null, { meta, credential }

