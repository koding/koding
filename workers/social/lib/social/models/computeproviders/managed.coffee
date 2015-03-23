# Managed VMs Provider implementation for ComputeProvider
# -------------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")


isValid = ({ipAddress, queryString, storage}, callback)->

  if ipAddress? and (ipAddress.split '.').length isnt 4
    return callback new KodingError \
      "Provided IP is not valid", "WrongParameter"

  if queryString? and (queryString.split '/').length isnt 8
    return callback new KodingError \
      "Provided queryString is not valid", "WrongParameter"

  if storage? and isNaN +storage
    return callback new KodingError \
      "Provided storage is not valid", "WrongParameter"

  return yes

getKiteIdOnly = (queryString)->
  "///////#{queryString.split('/').reverse()[0]}"

module.exports = class Managed extends ProviderInterface

  @providerSlug = 'managed'

  @ping = (client, options, callback)->

    {nickname} = client.r.account.profile
    callback null, "#{ @providerSlug } VMs rulez #{ nickname }!"


  @create = (client, options, callback)->

    { label, queryString, ipAddress } = options
    { r: { group, user, account } } = client

    return  unless isValid {queryString, ipAddress}, callback

    queryString = getKiteIdOnly queryString
    provider    = @providerSlug

    { guessNextLabel, fetchUserPlan, fetchUsage } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label)->
      fetchUserPlan client, (err, userPlan)->
        fetchUsage client, {provider}, (err, usage)->

          return callback err  if err?

          if usage.total >= userPlan.managed
            return callback new KodingError """
              Total limit of #{userPlan.managed}
              managed vm limit has been reached.
            """, "UsageLimitReached"

          meta =
            type          : @providerSlug
            storage_size  : 0 # sky is the limit.
            alwaysOn      : no

          callback null, {
            meta, label, credential: client.r.user.username
            postCreateOptions: { queryString, ipAddress }
          }


  @postCreate = (client, options, callback)->

    { r: { account } } = client
    { machine, postCreateOptions:{ queryString, ipAddress } } = options

    domain = ipAddress

    machine.update {
      $set: {
        queryString, domain, ipAddress
        status: {state: 'Running'}
      }
    }, (err)->

      return callback err  if err

      JWorkspace = require '../workspace'
      JWorkspace.createDefault client, machine.uid, callback


  @remove = (client, options, callback)->

    {machineId} = options
    JMachine    = require './machine'
    selector    = JMachine.getSelectorFor client, { machineId, owner: yes }

    JMachine.one selector, (err, machine)->
      if err or not machine
      then callback new KodingError "Machine not found."
      else machine.destroy client, callback


  @update = (client, options, callback)->

    { machineId, queryString, ipAddress, storage } = options
    { r: { group, user, account } } = client

    unless machineId? or (queryString? or ipAddress? or storage?)
      return callback new KodingError \
        "A valid machineId and an update option is required.", "WrongParameter"

    return  unless isValid {ipAddress, queryString, storage}, callback

    fieldsToUpdate = {}

    if ipAddress?
      domain = ipAddress
      fieldsToUpdate = {domain, ipAddress}

    fieldsToUpdate.queryString = queryString  if queryString?
    fieldsToUpdate['meta.storage'] = storage  if storage?

    JMachine = require './machine'
    selector = JMachine.getSelectorFor client, { machineId, owner: yes }
    selector.provider = @providerSlug

    JMachine.one selector, (err, machine)->

      if err? or not machine?
        return callback err or new KodingError "Machine object not found."

      machine.update $set: fieldsToUpdate, (err)->
        callback err
