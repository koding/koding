# Managed VMs Provider implementation for ComputeProvider
# -------------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
KONFIG            = require 'koding-config-manager'


validate = ({ ipAddress, queryString, storage }) ->

  if queryString? and (queryString.split '/').length isnt 8
    return { err : new KodingError 'Provided queryString is not valid', 'WrongParameter' }

  if storage? and isNaN +storage
    return { err : new KodingError 'Provided storage is not valid', 'WrongParameter' }

  return { err : null }

getKiteIdOnly = (queryString) ->
  "///////#{queryString.split('/').reverse()[0]}"


module.exports = class Managed extends ProviderInterface

  @providerSlug = 'managed'

  @ping = (client, options, callback) ->

    { nickname } = client.r.account.profile
    callback null, "#{ @providerSlug } VMs rulez #{ nickname }!"


  @create = (client, options, callback) ->

    { label, queryString, ipAddress } = options
    { r: { group, user, account } } = client

    { err } = validate { queryString, ipAddress }
    return callback err  if err

    queryString = getKiteIdOnly queryString
    provider    = @providerSlug

    { guessNextLabel } = require './computeutils'

    guessNextLabel { user, group, label, provider }, (err, label) ->
      return callback err  if err?

      meta =
        type          : Managed.providerSlug
        storage_size  : 0 # sky is the limit.
        alwaysOn      : no

      callback null, {
        meta, label, credential: client.r.user.username
        postCreateOptions: { queryString, ipAddress }
      }


  @postCreate = (client, options, callback) ->

    { r: { account } } = client
    { machine, postCreateOptions:{ queryString, ipAddress } } = options

    domain = ipAddress

    machine.update {
      $set: {
        queryString, domain, ipAddress
        status: { state: 'Running' }
      }
    }, (err) ->

      return callback err  if err

      JWorkspace = require '../workspace'
      JWorkspace.createDefault client, machine.uid, callback


  @remove = (client, options, callback) ->

    { machineId } = options
    JMachine    = require './machine'
    selector    = JMachine.getSelectorFor client, { machineId, owner: yes }

    JMachine.one selector, (err, machine) ->
      if err or not machine
        callback new KodingError 'Machine not found.'
      else
        machine.destroy client, (err) ->
          return callback err


  updateMachine = (selector, fieldsToUpdate, callback) ->
    JMachine    = require './machine'
    JMachine.one selector, (err, machine) ->

      if err? or not machine?
        return callback err or new KodingError 'Machine object not found.'

      machine.update { $set: fieldsToUpdate }, (err) ->
        callback err


  @update = (client, options, callback) ->

    { machineId, queryString, ipAddress, storage, managedProvider } = options
    { r: { group, user, account } } = client

    unless machineId? or (queryString? or ipAddress? or storage?)
      return callback new KodingError \
        'A valid machineId and an update option is required.', 'WrongParameter'

    { err } = validate { ipAddress, queryString, storage }
    return callback err  if err

    fieldsToUpdate = {}

    if ipAddress?
      domain = ipAddress
      fieldsToUpdate = { domain, ipAddress }

    fieldsToUpdate.queryString = getKiteIdOnly queryString  if queryString?

    fieldsToUpdate['meta.storage']         = storage          if storage?
    fieldsToUpdate['meta.managedProvider'] = managedProvider  if managedProvider?

    JMachine = require './machine'
    selector = JMachine.getSelectorFor client, { machineId, owner: yes }
    selector.provider = @providerSlug
    updateMachine selector, fieldsToUpdate, callback
