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


  ###*
   * @param {Object} options
  ###
  @create = (client, options, callback) ->

    { label, hostQueryString, credential } = options
    { r: { group, user, account } } = client

    provider = @providerSlug

    { guessNextLabel } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label) ->

      return callback err  if err

      meta = { hostQueryString, alwaysOn: yes }
      callback null, { meta, label, credential }


  @postCreate = (client, options, callback) ->

    { r: { account } } = client
    { machine } = options

    JWorkspace = require '../workspace'
    JWorkspace.createDefault client, machine.uid, callback


  @update = (client, options, callback) ->

    { ObjectId } = require 'bongo'
    { machineId, alwaysOn } = options
    { r: { group, user, account } } = client

    unless machineId? or alwaysOn?
      return callback new KodingError \
        'A valid machineId and an update option required.', 'WrongParameter'

    provider = @providerSlug

    selector       =
      $or          : [
        { _id      : ObjectId machineId }
        { uid      : machineId }
      ]
      users        :
        $elemMatch :
          id       : user.getId()
          sudo     : yes
          owner    : yes
      groups       :
        $elemMatch :
          id       : group.getId()

    updateMachine { selector, alwaysOn }, callback
