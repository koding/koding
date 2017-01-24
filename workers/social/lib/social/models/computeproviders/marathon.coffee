# Marathon Provider implementation for ComputeProvider
# -----------------------------------------------------


ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

{ updateMachine } = require './helpers'


module.exports = class Marathon extends ProviderInterface

  @providerSlug  = 'marathon'

  @bootstrapKeys = ['url']

  @secretKeys    = ['basic_auth_user', 'basic_auth_password']

  @ping = (client, options, callback) ->

    { nickname } = client.r.account.profile
    callback null, "#{ @providerSlug } is the best #{ nickname }!"

  @create = (client, options, callback) ->

    { credential, label } = options

    meta = {
      type          : @providerSlug
      assignedLabel : label
      region        : 'n/a'
      instance_type : 'n/a'
      storage_size  : 'n/a'
      image         : 'n/a'
    }

    callback null, { meta, credential }

  do @_requireTemplate
