{ Base, secure, signature } = require 'bongo'

KONFIG       = require 'koding-config-manager'
async        = require 'async'
_            = require 'underscore'

KodingError  = require '../../error'
KodingLogger = require '../kodinglogger'

{ Kite }     = require 'kite.js'
SockJs       = require 'node-sockjs-client'

# Kloud wrapper on social backend
#
module.exports = class Kloud extends Base

  @trait __dirname, '../../traits/protected'
  { permit } = require '../group/permissionset'

  @share()

  @set
    permissions    :
      'kite ping'  : ['member']
    sharedMethods  :
      static       :
        ping       : (signature Function)

  TIMEOUT = 10000

  getArgs = (client, args) ->

    args[0] ?= {}
    args[0].impersonate = client.connection.delegate.profile.nickname
    return args


  # calls kite.ping on Kloud on behalf of loggedin user
  #
  @ping  = (client, callback) ->
    @tell client, 'kite.ping', [], callback

  @ping$ = permit 'kite ping', { success: @ping }


  @tell = (client, method, args = [], callback) ->

    @transport
      .tell method, getArgs client, args
      .then  (res) ->
        callback null, res
        return res
      .timeout TIMEOUT
      .catch (err) ->
        callback err


  do ->

    options          =
      url            : "http://localhost:#{KONFIG.kloud.port}/kite"
      autoConnect    : yes
      autoReconnect  : yes
      transportClass : SockJs
      auth           :
        type         : 'kloudctl'
        key          : KONFIG.kloud.secretKey

    Kloud.transport = new Kite options
