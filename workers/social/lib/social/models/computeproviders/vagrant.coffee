# Vagrant Provider implementation for ComputeProvider
# -----------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

{ updateMachine } = require './helpers'


module.exports = class Vagrant extends ProviderInterface

  @providerSlug  = 'vagrant'

  @bootstrapKeys = ['queryString']

  @ping = (client, options, callback) ->

    { nickname } = client.r.account.profile
    callback null, "#{ @providerSlug } is the best #{ nickname }!"

  @create = (client, options, callback) ->

    { label, hostQueryString, credential } = options
    { r: { group, user, account } } = client

    provider = @providerSlug

    { guessNextLabel } = require './computeutils'

    assignedLabel = "#{label}"

    guessNextLabel { user, group, label, provider }, (err, label) =>

      return callback err  if err

      meta = {
        type      : @providerSlug
        alwaysOn  : yes
        hostQueryString
        assignedLabel
      }

      callback null, { meta, label, credential }

  do @_requireTemplate
