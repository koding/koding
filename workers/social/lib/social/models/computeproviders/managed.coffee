# Managed VMs Provider implementation for ComputeProvider
# -------------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class Managed extends ProviderInterface

  @providerSlug = 'managed'

  @ping = (client, options, callback)->

    {nickname} = client.r.account.profile
    callback null, "#{ @providerSlug } VMs rulez #{ nickname }!"


  @create = (client, options, callback)->

    { label, queryString, ipAddress } = options
    { r: { group, user, account } } = client

    provider = @providerSlug

    { guessNextLabel, fetchUserPlan, fetchUsage } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label)->
      fetchUserPlan client, (err, userPlan)->
        fetchUsage client, {provider}, (err, usage)->

          return callback err  if err?

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

      rootPath = '/' # We are not sure if the /home/nick directory exists

      JWorkspace = require '../workspace'
      JWorkspace.createDefault client, {machine, rootPath}, callback


  @remove = (client, options, callback)->

    {machineId} = options
    JMachine    = require './machine'
    selector    = JMachine.getSelectorFor client, { machineId, owner: yes }

    JMachine.one selector, (err, machine)->
      if err or not machine
      then callback new KodingError "Machine not found."
      else machine.destroy client, callback


  @update = (client, options, callback)->

    { machineId, queryString, ipAddress } = options
    { r: { group, user, account } } = client

    unless machineId? or queryString? or ipAddress?
      return callback new KodingError \
        "A valid machineId and an update option required.", "WrongParameter"

    # TODO add queryString and ipAddress validations here ~ GG

    JMachine = require './machine'
    selector = JMachine.getSelectorFor client, { machineId, owner: yes }

    JMachine.one selector, (err, machine)->

      if err? or not machine?
        return callback err or new KodingError "Machine object not found."

      domain = ipAddress

      machine.update $set: {queryString, domain, ipAddress}, (err)->
        callback err
