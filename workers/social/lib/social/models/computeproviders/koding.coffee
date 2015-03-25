# Koding VMs Provider implementation for ComputeProvider
# ------------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

SUPPORTED_REGIONS = ['us-east-1', 'eu-west-1', 'ap-southeast-1', 'us-west-2']

module.exports = class Koding extends ProviderInterface

  @providerSlug = 'koding'

  @ping = (client, options, callback)->

    {nickname} = client.r.account.profile
    callback null, "#{@providerSlug} is the best #{ nickname }!"


  @create = (client, options, callback)->

    { instanceType, label, storage, region } = options
    { r: { group, user, account }, clientIP } = client

    storage ?= 3

    storage  = +storage
    if isNaN storage
      return callback new KodingError \
      'Requested storage size is not valid.', 'WrongParameter'

    userIp   = clientIP or user.registeredFrom?.ip
    provider = @providerSlug

    { guessNextLabel, checkUsage
      fetchUserPlan, fetchUsage } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label)=>
      return callback err  if err

      fetchUserPlan client, (err, userPlan)=>
        return callback err  if err

        fetchUsage client, {provider}, (err, usage)->
          return callback err  if err

          if err = checkUsage usage, userPlan, storage
            return callback err

          region  = null  unless region in SUPPORTED_REGIONS
          region ?= (Regions.findRegion userIp, SUPPORTED_REGIONS).regions[0]

          meta =
            type          : 'amazon'
            region        : region ? SUPPORTED_REGIONS[0]
            source_ami    : '' # Kloud is updating this field after a successfull build
            instance_type : 't2.micro'
            storage_size  : storage
            alwaysOn      : no

          if 't2.medium' in userPlan.allowedInstances
            meta.instance_type = 't2.medium'

          callback null, {
            meta, label, credential: client.r.user.username
          }


  @postCreate = (client, options, callback)->

    { r: { account } } = client
    { machine } = options

    JDomainAlias = require '../domainalias'
    JDomainAlias.ensureTopDomainExistence account, machine._id, (err) ->
      return callback err  if err

      JWorkspace = require '../workspace'
      JWorkspace.createDefault client, machine.uid, callback


  @update = (client, options, callback)->

    { machineId, alwaysOn, resize } = options
    { r: { group, user, account } } = client

    unless machineId? or alwaysOn?
      return callback new KodingError \
        "A valid machineId and an update option required.", "WrongParameter"

    provider = @providerSlug

    JMachine = require './machine'

    { fetchUserPlan, fetchUsage } = require './computeutils'

    fetchUserPlan client, (err, userPlan)=>

      return callback err  if err?

      fetchUsage client, {provider}, (err, usage)->

        return callback err  if err?

        if alwaysOn and usage.alwaysOn >= userPlan.alwaysOn
          return callback new KodingError \
            """Total limit of #{userPlan.alwaysOn}
               always on vm limit has been reached.""", "UsageLimitReached"

        if resize?
          resize = +resize

          if isNaN resize
            return callback new KodingError \
            'Requested new size is not valid.', 'WrongParameter'
          else if resize > userPlan.storage
            return callback new KodingError \
            """Requested new size exceeds allowed
               limit of #{userPlan.storage}GB.""", "UsageLimitReached"
          else if resize < 3
            return callback new KodingError \
            """New size can't be less than 3GB.""", "WrongParameter"

        { ObjectId } = require 'bongo'

        selector  =
          $or     : [
            { _id : ObjectId machineId }
            { uid : machineId }
          ]
          users   : $elemMatch: id: user.getId(), sudo: yes, owner: yes
          groups  : $elemMatch: id: group.getId()

        JMachine.one selector, (err, machine)->

          if err? or not machine?
            err ?= new KodingError "Machine object not found."
            return callback err

          fieldsToUpdate = {}

          if alwaysOn?
            fieldsToUpdate['meta.alwaysOn'] = alwaysOn

          if resize?

            storageSize = machine.meta?.storage_size ? 3

            if (resize - storageSize) + usage.storage > userPlan.storage
              return callback new KodingError \
              """Requested new size exceeds allowed
                 limit of #{userPlan.storage}GB.""", "UsageLimitReached"
            else if resize == machine.getAt 'meta.storage_size'
              return callback new KodingError \
              """Requested new size is same with current
                 storage size (#{resize}GB).""", "SameValueForResize"

            fieldsToUpdate['meta.storage_size'] = resize

          machine.update

            $set: fieldsToUpdate

          , (err)-> callback err


  @fetchAvailable = (client, options, callback)->

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
