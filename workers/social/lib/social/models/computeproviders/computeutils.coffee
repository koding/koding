# coffeelint: disable=cyclomatic_complexity
KodingError    = require '../../error'

PROVIDERS      =
  aws          : require './aws'
  softlayer    : require './softlayer'
  rackspace    : require './rackspace' # TODO: stacks not supported, remove or update this ~ GG
  digitalocean : require './digitalocean'
  azure        : require './azure'
  google       : require './google'
  managed      : require './managed'   # stacks not supported ~ GG
  vagrant      : require './vagrant'
  marathon     : require './marathon'

PLANS          = require './plans'

# When adding up the storage usage totals, the DEFAULT_STORAGE_USAGE is
# the default value to add, if no storage is defined.
DEFAULT_STORAGE_USAGE = 3

PROVIDERS_WITHOUT_CREDS = ['managed']

reviveProvisioners = (client, provisioners, callback, revive = no) ->

  if not revive or not provisioners or provisioners.length is 0
    return callback null, provisioners

  JProvisioner = require './provisioner'

  # TODO add multiple provisioner support
  provisioner = provisioners[0]

  JProvisioner.one$ client, { slug: provisioner }, (err, provision) ->

    if err or not provision?
      console.warn "Requested provisioner: #{provisioner} not found !"
      console.warn "or not accessible for #{client.r.user.username} !!"
      callback null, []
    else
      callback null, [ provision.slug ]


reviveGroupLimits = (group, callback) ->

  # Support for test plan data to cover test cases that we need
  # to be able to run tests for different plans but we don't
  # need to update plan data on payment endpoint ~ GG
  if testLimit = group?.getAt 'config.testlimit'
    group._activeLimit = testLimit
  else
    group._activeLimit = 'unlimited'

  callback null, group


reviveCredential = (client, credential, callback) ->

  [credential, callback] = [callback, credential]  unless callback?

  if not credential?
    return callback null

  if credential.bongo_?.constructorName is 'JCredential'
    callback null, credential
  else
    JCredential = require './credential'
    JCredential.fetchByIdentifier client, credential, callback


reviveClient = (client, callback, options) ->

  { shouldReviveClient, shouldFetchGroupLimit } = options ? {}
  shouldReviveClient ?= yes

  return callback null  unless shouldReviveClient

  { connection: { delegate:account }, context: { group } } = client

  return callback new KodingError 'Account not set'  unless account
  return callback new KodingError 'group not set'  unless group

  JGroup = require '../group'
  JGroup.one { slug: group }, (err, groupObj) ->

    return callback err  if err
    return callback new KodingError 'Group not found'  unless groupObj

    res = { account, group: groupObj }

    account.fetchUser (err, user) ->

      return callback err  if err
      return callback new KodingError 'User not found'  unless user

      res.user = user

      if shouldFetchGroupLimit

        reviveGroupLimits res.group, (err, group) ->
          return callback err  if err
          res.group = group
          callback null, res

      else

        callback null, res


reviveOauth = (client, oauthProvider, callback) ->

  JForeignAuth = require '../foreignauth'
  JForeignAuth.fetchData client, (err, foreignAuth) ->
    if err or not foreignAuth or not authData = foreignAuth[oauthProvider]
    then callback new KodingError "Authentication not found for #{oauthProvider}"
    else callback null, authData


locks = []

lockProcess = (client) ->
  { nickname } = client.connection.delegate.profile
  if (locks.indexOf nickname) > -1
    # console.log "[LOCKER] User #{nickname} requested to acquire lock again!"
    return false
  else
    # console.log "[LOCKER] User #{nickname} locked."
    locks.push nickname
    return yes

unlockProcess = (client) ->
  { nickname } = client.connection.delegate.profile
  t = locks.indexOf nickname
  if t > -1
    # console.log "[UNLOCKER] User #{nickname} unlocked."
    locks[t..t] = []
  # else
  #   console.log "[UNLOCKER] User #{nickname} was not locked, nothing to do."


revive = do -> (
  {
    shouldReviveClient
    shouldPassCredential
    shouldReviveProvider
    shouldReviveProvisioners
    shouldFetchGroupLimit
    shouldLockProcess
    shouldReviveOAuth
    hasOptions
  }, fn) ->

    (client, options, _callback) ->

      hasOptions ?= yes

      unless hasOptions
        [options, _callback] = [_callback, options]
        options = {}

      unless typeof _callback is 'function'
        _callback = (err) ->
          console.error 'Unhandled error:', err?.message or err

      if shouldLockProcess

        unless lockProcess client
          return _callback new KodingError \
            'There is a process on-going, try again later.', 'Busy'

        callback = (rest...) ->
          unlockProcess client
          _callback rest...

      else

        callback = _callback

      shouldReviveProvider ?= yes

      { provider, credential, provisioners } = options

      if shouldReviveProvider
        if not provider or not provider_ = PROVIDERS[provider]
          return callback new KodingError 'No such provider.', 'ProviderNotFound'
        else
          provider_.slug   = provider
          options.provider = provider_

      reviveClient client, (err, revivedClient) =>

        return callback err       if err
        client.r = revivedClient  if revivedClient?

        # OAUTH Check

        if shouldReviveOAuth

          unless options.provider
            return callback new KodingError 'No such provider.', 'ProviderNotFound'

          reviveOauth client, options.provider, (err, oauth) =>
            return callback err     if err
            client.r.oauth = oauth  if oauth?

            if hasOptions
            then fn.call this, client, options, callback
            else fn.call this, client, callback

          return

        if shouldPassCredential and not credential?
          unless provider in PROVIDERS_WITHOUT_CREDS
            return callback new KodingError \
              'Credential is required.', 'MissingCredential'

        reviveCredential client, credential, (err, cred) =>

          if err then return callback err

          if shouldPassCredential and not cred?
            unless provider in PROVIDERS_WITHOUT_CREDS
              return callback \
                new KodingError 'Credential failed.', 'AccessDenied'
          else
            options.credential = cred.identifier  if cred?.identifier

          reviveProvisioners client, provisioners, (err, provisioners) =>

            options.provisioners = provisioners  if provisioners?

            if hasOptions
            then fn.call this, client, options, callback
            else fn.call this, client, callback

          , shouldReviveProvisioners

      , { shouldReviveClient, shouldFetchGroupLimit }


checkTemplateUsage = (template, account, callback) ->

  { Relationship } = require 'jraphical'
  Relationship.count
    targetId   : template.getId()
    targetName : 'JStackTemplate'
    sourceId   : account.getId()
  , (err, count) ->

    if err or count > 0
    then callback new KodingError 'Template in use', 'InUse', err
    else callback null


fetchGroupStackTemplate = (client, callback) ->

  reviveClient client, (err, res) ->

    return callback err  if err

    { user, group, account } = res

    unless group.stackTemplates?.length
      console.warn "There is no stack template assigned for #{group.slug} group"

      # This is a fallback mechanism and valid only for production. ~ GG
      if group.slug is 'koding'
        { ObjectId } = require 'bongo'
        group.stackTemplates = [ObjectId '53fe557af052f8e9435a04fa']
        console.error '[critical] Koding group template is not set!'
      else
        return callback new KodingError 'Template not set', 'NotFound'

    # TODO Make this works with multiple stacks ~ gg
    stackTemplateId = group.stackTemplates[0]

    # TODO make all these in seperate functions
    JStackTemplate = require './stacktemplate'
    JStackTemplate.one { _id: stackTemplateId }, (err, template) ->

      if err
        console.warn "Failed to fetch stack template for #{group.slug} group"
        console.warn "Failed to create stack for #{user.username} !!"
        return callback new KodingError 'Template not set', 'NotFound', err

      if not template?
        console.warn "Stack template is not exists for #{group.slug} group"
        console.warn "Failed to create stack for #{user.username} !!"
        return callback new KodingError 'Template not found', 'NotFound', err

      checkTemplateUsage template, account, (err) ->
        return callback err  if err?

        res.template = template
        callback null, res

  , { shouldFetchGroupLimit: yes }


guessNextLabel = (options, callback) ->

  { user, group, provider, label } = options

  return callback null, label  if label?

  JMachine   = require './machine'

  # Following query will try to sort possible JMachines ordered by
  # create date and will return the newest one with following cases
  #  - provider must be equal to provided provider
  #  - user and group must be same and user must be owner of the machine
  #  - label needs to start with provider name and ends with "-vm-{0-9}" ~ GG
  selector       =
    provider     : provider
    users        :
      $elemMatch :
        id       : user.getId()
        sudo     : yes
        owner    : yes
    groups       :
      $elemMatch :
        id       : group.getId()
    label        : ///^#{provider}-vm-[0-9]*$///

  options        =
    limit        : 1
    sort         :
      createdAt  : -1

  JMachine.one selector, options, (err, machine) ->

    return callback err  if err?
    unless machine?
      callback null, "#{provider}-vm-0"
    else
      index = +(machine.label.split "#{provider}-vm-")[1]
      callback null, "#{provider}-vm-#{index+1}"


fetchUserPlan = (client, callback) ->

  { clone } = require 'underscore'
  plan = 'free'

  # we need to clone the plan data since we are using global data here,
  # when we modify it at line 84 everything will be broken after the
  # first operation until this social restarts ~ GG
  planData  = clone PLANS[plan]

  JReward   = require '../rewards'
  JReward.fetchEarnedAmount
    unit     : 'MB'
    type     : 'disk'
    originId : client.r.account.getId()

  , (err, amount) ->

    amount = 0  if err
    planData.storage += Math.floor amount / 1000

    callback err, planData


checkLimit = (usage, plan, storage) ->

  err = null
  if usage.total + 1 > plan.total
    err = "Total limit of #{plan.total} machines has been reached."
  else if storage? and usage.storage + storage > plan.storage
    err = "Total limit of #{plan.storage}GB storage limit has been reached."

  if err then return new KodingError err


# Signature generator for given apiMap like in
# client/app/lib/kite/kites/kiteapimap ~ GG
generateSignatures = (apiMap, extras = []) ->

  { signature } = require 'bongo'

  signatures = {}
  for own method, rpcMethod of apiMap
    signatures[method] = (signature Object, Function)

  for method in extras
    signatures[method] = (signature Object, Function)

  return signatures


# Flatten's given object with keys prefixed ~ GG
flattenPayload = (payload, prefix = 'payload', res = {}) ->

  for own key, value of payload
    key = "#{prefix}_#{key}"
    if value and 'object' is typeof value
    then res = flattenPayload value, key, res
    else res[key] = "#{value}"

  return res


module.exports = {
  fetchUserPlan, fetchGroupStackTemplate
  PLANS, PROVIDERS, guessNextLabel, checkLimit
  revive, reviveClient, reviveCredential, reviveGroupLimits
  checkTemplateUsage, generateSignatures, flattenPayload
}
