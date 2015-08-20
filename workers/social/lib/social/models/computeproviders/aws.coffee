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


  @fetchAvailable = (client, options, callback) ->

    callback null, [
      {
        name  : 't2.micro'
        title : 'T2 micro'
        spec  : {
          cpu : 1, ram: 1, storage: 4
        }
        price : '$0.013 per Hour'
      }
      {
        name  : 'm1.small'
        title : 'M1 small'
        spec  : {
          cpu : 1, ram: 1.7, storage: 160
        }
        price : '$0.044 per Hour'
      }
      {
        name  : 'm3.medium'
        title : 'M3 medium'
        spec  : {
          cpu : 1, ram: 3.75, storage: 4
        }
        price : '$0.070 per Hour'
      }
      {
        name  : 'm3.large'
        title : 'M3 large'
        spec  : {
          cpu : 2, ram: 7.5, storage: 32
        }
        price : '$0.140 per Hour'
      }
      {
        name  : 'm3.xlarge'
        title : 'M3 xlarge'
        spec  : {
          cpu : 4, ram: 15, storage: 80
        }
        price : '$0.280 per Hour'
      }
      {
        name  : 'm3.2xlarge'
        title : 'M3 2xlarge'
        spec  : {
          cpu : 8, ram: 30, storage: 160
        }
        price : '$0.560 per Hour'
      }
    ]


