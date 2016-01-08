# Softlayer Provider implementation for ComputeProvider
# -----------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

{ updateMachine } = require './helpers'


module.exports = class Softlayer extends ProviderInterface

  @providerSlug = 'softlayer'

  @ping = (client, options, callback) ->

    { nickname } = client.r.account.profile
    callback null, "#{ @providerSlug } is the best #{ nickname }!"


  ###*
   * @param {Object} options
   * @param {String=} options.snapshotId - The unique snapshotId to create
   *   this machine from, if any.
  ###
  @create = (client, options, callback) ->

    { label } = options
    { r: { group, user, account } } = client

    storage  = 25
    provider = @providerSlug

    { guessNextLabel, checkUsage
      fetchUserPlan, fetchUsage } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label) ->
      return callback err  if err

      fetchUserPlan client, (err, userPlan) ->
        return callback err  if err

        fetchUsage client, { provider }, (err, usage) ->
          return callback err  if err

          # Softlayer vm limit is 1 for all plans, until we decide ~ GG
          userPlan.total = 1

          if err = checkUsage usage, userPlan
            return callback err

          meta            =
            type          : 'softlayer'
            storage_size  : storage
            datacenter    : 'sjc01'
            alwaysOn      : no

          callback null, { meta, label, credential: client.r.user.username }


  @postCreate = (client, options, callback) ->

    { r: { account } } = client
    { machine } = options

    JDomainAlias = require '../domainalias'
    JDomainAlias.ensureTopDomainExistence account, machine._id, (err) ->
      return callback err  if err

      JWorkspace = require '../workspace'
      JWorkspace.createDefault client, machine.uid, callback


  @update = (client, options, callback) ->

    { machineId, alwaysOn } = options
    { r: { group, user, account } } = client

    unless machineId? or alwaysOn?
      return callback new KodingError \
        'A valid machineId and an update option required.', 'WrongParameter'

    provider = @providerSlug

    { fetchUserPlan, fetchUsage } = require './computeutils'

    fetchUserPlan client, (err, userPlan) ->

      return callback err  if err?

      fetchUsage client, { provider }, (err, usage) ->

        return callback err  if err?

        if alwaysOn and usage.alwaysOn >= userPlan.alwaysOn
          return callback new KodingError \
            """Total limit of #{userPlan.alwaysOn}
               always on vm limit has been reached.""", 'UsageLimitReached'

        { ObjectId } = require 'bongo'

        selector  =
          $or     : [
            { _id : ObjectId machineId }
            { uid : machineId }
          ]
          users        :
            $elemMatch :
              id       : user.getId()
              sudo     : yes
              owner    : yes
          groups       :
            $elemMatch :
              id       : group.getId()

        updateMachine { selector, alwaysOn, usage, userPlan }, callback
