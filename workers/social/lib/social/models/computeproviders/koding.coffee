
ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
{clone}           = require 'underscore'
{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class Koding extends ProviderInterface

  SUPPORTED_REGIONS    = ['us-east-1', 'eu-west-1', 'ap-southeast-1', 'us-west-2']

  PLANS                =
    free               :
      total            : 1
      alwaysOn         : 0
      storage          : 3
      allowedInstances : ['t2.micro']
    hobbyist           :
      total            : 1
      alwaysOn         : 1
      storage          : 10
      allowedInstances : ['t2.micro']
    developer          :
      total            : 3
      alwaysOn         : 1
      storage          : 25
      allowedInstances : ['t2.micro']
    professional       :
      total            : 5
      alwaysOn         : 2
      storage          : 50
      allowedInstances : ['t2.micro']
    super              :
      total            : 10
      alwaysOn         : 5
      storage          : 100
      allowedInstances : ['t2.micro']
    koding             :
      total            : 20
      alwaysOn         : 20
      storage          : 200
      allowedInstances : ['t2.micro', 't2.small', 't2.medium']
    betatester         :
      total            : 1
      alwaysOn         : 1
      storage          : 3
      allowedInstances : ['t2.micro']

  @fetchPlans = (client, options, callback)->

    callback null, clone PLANS


  @ping = (client, options, callback)->

    callback null, "Koding is the best #{ client.r.account.profile.nickname }!"


  @fetchUserPlan = (client, callback)->

    Payment = require '../payment'
    Payment.subscriptions client, {}, (err, subscription)=>

      if err? or not subscription?
      then plan = 'free'
      else plan = subscription.planTitle

      # we need to clone the plan data since we are using global data here,
      # when we modify it at line 84 everything will be broken after the
      # first operation until this social restarts ~ GG
      planData  = clone PLANS[plan]

      JReward   = require '../rewards'
      JReward.fetchEarnedAmount
        unit     : 'MB'
        type     : 'disk'
        originId : client.r.account.getId()

      , (err, amount)->

        amount = 0  if err
        planData.storage += Math.floor amount / 1000

        callback err, planData


  checkUsage = (usage, plan, storage)->

    err = null
    if usage.total + 1 > plan.total
      err = "Total limit of #{plan.total} machines has been reached."
    else if usage.storage + storage > plan.storage
      err = "Total limit of #{plan.storage}GB storage limit has been reached."

    if err then return new KodingError err


  guessNextLabel = (user, group, label, callback)->

    return callback null, label  if label?

    JMachine   = require './machine'

    selector   =
      provider : 'koding'
      users    : $elemMatch: id: user.getId()
      groups   : $elemMatch: id: group.getId()
      label    : /^koding-vm-[0-9]*$/
    options    =
      limit    : 1
      sort     : createdAt : -1


    JMachine.one selector, options, (err, machine)->

      return callback err  if err?
      unless machine?
        callback null, 'koding-vm-0'
      else

        index = +(machine.label.split 'koding-vm-')[1]
        callback null, "koding-vm-#{index+1}"



  @create = (client, options, callback)->

    { instanceType, label, storage, region } = options
    { r: { group, user, account }, clientIP } = client

    storage ?= 3
    userIp   = clientIP or user.registeredFrom?.ip

    guessNextLabel user, group, label, (err, label)=>

      @fetchUserPlan client, (err, userPlan)=>

        @fetchUsage client, options, (err, usage)->

          return callback err  if err?

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

    JMachine = require './machine'

    @fetchUserPlan client, (err, userPlan)=>

      return callback err  if err?

      @fetchUsage client, options, (err, usage)->

        return callback err  if err?

        if alwaysOn and usage.alwaysOn >= userPlan.alwaysOn
          return callback new KodingError \
            """Total limit of #{userPlan.alwaysOn}
               always on vm limit has been reached.""", "UsageLimitReached"

        if resize?
          if resize > userPlan.storage
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
          users   : $elemMatch: id: user.getId()
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


  @fetchUsage = (client, options, callback)->

    JMachine  = require './machine'

    { r: { group, user } } = client

    selector        = { provider: 'koding' }
    selector.users  = $elemMatch: id: user.getId(), sudo: yes, owner: yes
    selector.groups = $elemMatch: id: group.getId()

    JMachine.some selector, limit: 30, (err, machines)->

      return callback err  if err?

      total    = machines.length
      alwaysOn = 0
      storage  = 0

      machines.forEach (machine)->
        alwaysOn++  if machine.meta.alwaysOn
        storage += machine.meta.storage_size ? 3

      callback null, { total, alwaysOn, storage }


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
