ProviderInterface = require './providerinterface'
{ updateMachine } = require './helpers'
KodingError       = require '../../error'

module.exports = class Aws extends ProviderInterface

  @providerSlug  = 'aws'

  @bootstrapKeys = ['key_pair', 'rtb', 'acl']

  @sensitiveKeys = ['access_key', 'secret_key']


  @ping = (client, options, callback) ->
    callback null, "#{ @providerSlug } rulez #{ client.r.account.profile.nickname }!"


  @create = (client, options, callback) ->

    { credential, instanceType, region, ami, storage, label } = options

    storage ?= 8
    if isNaN storage
      return callback new KodingError \
      'Requested storage size is not valid.', 'WrongParameter'

    meta =
      type          : @providerSlug
      region        : region ? 'us-east-1'
      instance_type : instanceType ? 't2.nano'
      storage_size  : storage
      assignedLabel : label

    if ami?
      meta.source_ami = ami

    callback null, { meta, credential }


  @update = (client, options, callback) ->

    { machineId, alwaysOn } = options
    { r: { group, user, account } } = client

    unless machineId? or alwaysOn?
      return callback new KodingError \
        'A valid machineId and an update option required.', 'WrongParameter'

    JMachine = require './machine'
    selector = JMachine.getSelectorFor client, { machineId, owner: yes }
    selector.provider = @providerSlug

    updateMachine { selector, alwaysOn }, callback
