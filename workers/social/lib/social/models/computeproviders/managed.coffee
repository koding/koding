# Managed VMs Provider implementation for ComputeProvider
# -------------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class Managed extends ProviderInterface

  @ping = (client, options, callback)->

    callback null, "Managed VMs rulez #{ client.r.account.profile.nickname }!"


  @create = (client, options, callback)->

    { label, queryString, ipAddress } = options
    { r: { group, user, account } } = client

    provider = 'managed'

    { guessNextLabel, fetchUserPlan, fetchUsage } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label)->
      fetchUserPlan client, (err, userPlan)->
        fetchUsage client, options, (err, usage)->

          return callback err  if err?

          meta =
            type          : 'managed'
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


    JMachine = require './machine'
    JMachine.one {_id: machineId, provider}, (err, machine)->
      machine.destroy client, callback
