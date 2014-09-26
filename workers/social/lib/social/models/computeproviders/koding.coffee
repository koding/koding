
ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class Koding extends ProviderInterface

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


  @fetchPlans = (client, options, callback)->

    callback null, PLANS


  @ping = (client, options, callback)->

    callback null, "Koding is the best #{ client.r.account.profile.nickname }!"


  @fetchUserPlan = (client, callback)->

    Payment = require '../payment'
    Payment.subscriptions client, {}, (err, subscription)=>

      if err? or not subscription?
      then plan = 'free'
      else plan = subscription.planTitle

      callback err, PLANS[plan]


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
      provider : "koding"
      users    : $elemMatch: id: user.getId()
      groups   : $elemMatch: id: group.getId()
      label    : /^koding-vm-[0-9]*$/
    options    =
      limit    : 1
      sort     : createdAt : -1


    JMachine.one selector, options, (err, machine)->

      return callback err  if err?
      unless machine?
        callback null, "koding-vm-0"
      else

        index = +(machine.label.split 'koding-vm-')[1]
        callback null, "koding-vm-#{index+1}"



  @create = (client, options, callback)->

    { instanceType, label, storage } = options
    { r: { group, user, account } } = client

    storage ?= 3

    @fetchUserPlan client, (err, userPlan)=>

      return callback err  if err?

      @fetchUsage client, options, (err, usage)->

        return callback err  if err?

        if err = checkUsage usage, userPlan, storage
          return callback err

        guessNextLabel user, group, label, (err, label)->

          meta =
            type          : "amazon"
            region        : "us-east-1"
            source_ami    : "ami-2651904e"
            instance_type : "t2.micro"
            storage_size  : storage
            alwaysOn      : no

          callback null, {
            meta, label, credential: client.r.user.username
          }


  @update = (client, options, callback)->

    { machineId, alwaysOn } = options
    { r: { group, user, account } } = client

    unless machineId? or alwaysOn?
      return callback new KodingError \
        "A valid machineId and alwaysOn state required."

    JMachine = require './machine'

    @fetchUserPlan client, (err, userPlan)=>

      # Commented-out this since if its failing to fetch plan
      # its falling back to 'free' as default. ~ GG
      # return callback err  if err?

      @fetchUsage client, options, (err, usage)->

        return callback err  if err?

        if alwaysOn and usage.alwaysOn >= userPlan.alwaysOn
          return callback new KodingError \
            """Total limit of #{userPlan.alwaysOn}
               always on vm limit has been reached.""", "UsageLimitReached"

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


          machine.update

            $set: "meta.alwaysOn": alwaysOn

          , (err)-> callback err


  @fetchUsage = (client, options, callback)->

    JMachine  = require './machine'

    { r: { group, user } } = client

    selector        = { provider: "koding" }
    selector.users  = $elemMatch: id: user.getId()
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
        name  : "t2.micro"
        title : "Small 1x"
        spec  : {
          cpu : 1, ram: 1, storage: 4
        }
        price : 'free'
      }
    ]