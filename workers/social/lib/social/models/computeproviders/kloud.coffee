{ Base, secure } = require 'bongo'

{ Kite } = require 'kite.js'
SockJs   = require 'node-sockjs-client'
KONFIG   = require 'koding-config-manager'

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
      static       : generateSignatures KiteAPIMap.kloud


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


  @tell = (client, method, payload, callback) ->

    [ err, payload ] = preparePayload client, payload
    return callback err  if err

    @transport
      .tell method, payload
      .timeout TIMEOUT
      .then  (res) -> callback null, res
      .catch (err) -> callback err


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
