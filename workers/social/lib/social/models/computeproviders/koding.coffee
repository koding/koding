# Koding VMs Provider implementation for ComputeProvider
# ------------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
{ argv }          = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

{ updateMachine, validateResizeByUserPlan } = require './helpers'

SUPPORTED_REGIONS = ['us-east-1', 'eu-west-1', 'ap-southeast-1', 'us-west-2']

module.exports = class Koding extends ProviderInterface

  @providerSlug = 'koding'

  @ping = (client, options, callback) ->

    { nickname } = client.r.account.profile
    callback null, "#{ @providerSlug } is the best #{ nickname }!"


  ###*
   * @param {Object} options
   * @param {String=} options.snapshotId - The unique snapshotId to create
   *   this machine from, if any.
  ###
  @create = (client, options, callback) ->

    { instanceType, label, storage, region, snapshotId } = options
    { r: { group, user, account }, clientIP } = client

    storage ?= 3

    storage  = +storage
    if (isNaN storage) or not (3 <= storage <= 100)
      return callback new KodingError \
      'Requested storage size is not valid.', 'WrongParameter'

    userIp   = clientIP or user.registeredFrom?.ip
    provider = @providerSlug

    { guessNextLabel, checkUsage
      fetchUserPlan, fetchUsage } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label) ->
      return callback err  if err

      fetchUserPlan client, (err, userPlan) ->
        return callback err  if err

        fetchUsage client, { provider }, (err, usage) ->
          return callback err  if err

          if err = checkUsage usage, userPlan, storage
            return callback err

          region  = null  unless region in SUPPORTED_REGIONS
          region ?= (Regions.findRegion userIp, SUPPORTED_REGIONS).regions[0]

          meta =
            type          : 'aws'
            region        : region ? SUPPORTED_REGIONS[0]
            source_ami    : '' # Kloud is updating this field after a successfull build
            instance_type : 't2.micro'
            storage_size  : storage
            alwaysOn      : no

          if 't2.medium' in userPlan.allowedInstances
            meta.instance_type = 't2.medium'

          unless snapshotId
            return callback null, { meta, label, credential: client.r.user.username }

          JSnapshot = require './snapshot'
          JSnapshot.verifySnapshot client, { storage, snapshotId }, (err, snapshot) ->
            meta.snapshotId = snapshot.snapshotId  if snapshot
            callback err, { meta, label, credential: client.r.user.username }


  @postCreate = (client, options, callback) ->

    { r: { account } } = client
    { machine } = options

    JDomainAlias = require '../domainalias'
    JDomainAlias.ensureTopDomainExistence account, machine._id, (err) ->
      return callback err  if err

      JWorkspace = require '../workspace'
      JWorkspace.createDefault client, machine.uid, callback


  @update = (client, options, callback) ->

    { machineId, alwaysOn, resize } = options
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

        if resize?
          resize = +resize

          if err = validateResizeByUserPlan resize, userPlan
            return callback err

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

        updateMachine { selector, alwaysOn, resize, usage, userPlan }, callback


  @fetchAvailable = (client, options, callback) ->

    callback null, [
      {
        name  : 't2.micro'
        title : 'Small 1x'
        spec  : {
          cpu : 1, ram: 1, storage: 4
        }
        price : 'free'
      }
    ]

