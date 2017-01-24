# Softlayer Provider implementation for ComputeProvider
# -----------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

{ updateMachine } = require './helpers'


module.exports = class Softlayer extends ProviderInterface

  @providerSlug  = 'softlayer'

  @bootstrapKeys = ['key_id']

  @secretKeys    = ['api_key']

  @ping = (client, options, callback) ->

    { nickname } = client.r.account.profile
    callback null, "#{ @providerSlug } is the best #{ nickname }!"

  @create = (client, options, callback) ->

    { credential, region, image, label } = options

    meta = {
      type          : @providerSlug
      assignedLabel : label
      region        : region ? 'dal09'
      instance_type : 'virtual_guest'
      storage_size  : 10
      image         : image ? 'UBUNTU_14_64'
    }

    callback null, { meta, credential }

  do @_requireTemplate
