{ Base, secure, signature } = require 'bongo'

{ Kite } = require 'kite.js'
SockJs   = require 'node-sockjs-client'
KONFIG   = require 'koding-config-manager'


KodingError = require '../../error'
clientRequire = require '../../clientrequire'
KiteAPIMap = clientRequire 'app/lib/kite/kites/kiteapimap'
{ generateSignatures } = require './computeutils'


# Kloud wrapper on social backend
#
module.exports = class Kloud extends Base

  @trait __dirname, '../../traits/protected'
  { permit } = require '../group/permissionset'

  @share()

  @set
    permissions    :
      'kite access': ['member']
    sharedMethods  :
      static       : generateSignatures KiteAPIMap.kloud, ['destroyStack']

  NOTIFY_ON_CHANGE = [
    'apply', 'bootstrap', 'destroy', 'info'
    'stop', 'start', 'build', 'restart'
  ]

  TIMEOUT = 15000


  # Helper to create methods dynamically for KiteAPIMap definition ~ GG
  #
  @createMethod = (ctx, { method, rpcMethod }) ->

    ctx[method] = (client, payload, callback) ->
      @tell client, rpcMethod, payload, callback

  # Create methods for both fe and be versions
  # all uses same single permission for fe requests ~ GG
  #
  for own method, rpcMethod of KiteAPIMap.kloud
    @[method] = @createMethod this, { method, rpcMethod }
    @["#{method}$"] = permit 'kite access', { success: @[method] }


  preparePayload = (client, payload) ->

    payload ?= {}

    payload.impersonate = client.connection.delegate.profile.nickname
    payload.groupName   = client.context.group

    { provider, machineId, stackId } = payload

    if not provider and (machineId or stackId)
      return [ new KodingError 'Provider is required' ]

    return [ null, [ payload ] ]


  notify = (client, data) ->

    { machineId, stackId, provider } = data.payload[0]

    account      = client.connection.delegate
    data.group   = client.context.group
    data.payload = { machineId, stackId, provider }

    account.sendNotification 'KloudActionOverAPI', data


  @tell = (client, method, payload, callback) ->

    [ err, payload ] = preparePayload client, payload
    return callback err  if err

    @transport
      .tell method, payload
      .timeout TIMEOUT
      .then  (res) ->
        if method in NOTIFY_ON_CHANGE
          notify client, { method, payload, res }
        callback null, res
      .catch (err) -> callback err


  @destroyStack = permit 'kite access',

    success: (client, options, callback) ->

      { stackId, destroyTemplate } = options

      JComputeStack = require '../stack'
      JComputeStack.one$ client, { _id: stackId }, (err, stack) =>
        return callback err  if err
        return callback new KodingError 'No such stack found'  unless stack

        options    =
          stackId  : stack.getId()
          provider : (stack.getAt 'config.requiredProviders')[0]
          destroy  : true

        baseStackId = stack.getAt 'baseStackId'

        @buildStack client, options, (err) ->
          return callback err  if err
          return callback null  unless destroyTemplate

          JStackTemplate = require './stacktemplate'
          JStackTemplate.one$ client, { _id: baseStackId }, (err, template) ->
            return callback err  if err
            return callback null  unless template

            template.delete client, callback


  do ->

    options               =
      url                 : "http://localhost:#{KONFIG.publicPort}/kloud/kite"
      autoConnect         : yes
      autoReconnect       : yes
      transportClass      : SockJs
      auth                :
        key               : KONFIG.kloud.kloudSecretKey
        type              : 'kloudSecret'
      heartbeatTimeout    : 30 * 1000 # 30 seconds
      # Force XHR for all kind of kite connection
      protocols_whitelist : ['xhr-polling']

    Kloud.transport = new Kite options
