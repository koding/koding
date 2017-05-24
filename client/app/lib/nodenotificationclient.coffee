debug = require('debug') 'app:nodenotification'

kd = require 'kd'

SockJS = require 'sockjs-client'
backoff = require 'backoff'

kookies = require 'kookies'
globals = require 'globals'

nick = require 'app/util/nick'


module.exports = class NodeNotificationClient extends kd.Object

  SUBSCRIBE_ENDPOINT = '/notify/subscribe' # this can be taken from config ~ GG


  constructor: (options = {}, data) ->

    super options, data


    @_bo = backoff.exponential
      initialDelay : 1200
      maxDelay     : 15000

    @on 'ready', =>
      debug 'connected and verified, listening for new events...'
      @_bo.reset()

    @_bo.failAfter 15

    @_bo.on 'backoff', (trial, delay) ->
      return  if trial is 0
      debug "failed to connect on trial #{trial}, trying again in #{delay}ms..."

    @_bo.on 'fail', ->
      debug 'failed to connect, giving up.'


  connect: ->

    @_bo.on 'ready', =>
      @_socket?.close()
      delete @_socket
      @_connect()

    @_bo.backoff()


  _connect: ->

    debug 'initiating the socket connection...'
    @_socket = new SockJS SUBSCRIBE_ENDPOINT

    @_socket.onmessage = @bound '_handleNewMessage'
    @_socket.onclose   = @bound '_handleClose'
    @_socket.onopen    = @bound '_handleOpen'

    return this


  close: (internal = no) ->

    debug 'closing the connection'
    @_socket?.close()


  _handleOpen: ->

    debug 'connection established, sending auth message...'
    @_send @_getAuth()
    kd.utils.wait 5000, =>
      @_bo.backoff()  unless @readyState


  _handleClose: (event) ->

    debug 'connection closed by remote.'

    # this is due to readyState implementation in kd.Object ~ GG
    @readyState = 0
    @once 'ready', => @readyState = 1

    @_bo.backoff()  if event?.code > 1000


  _handleNewMessage: (message) ->

    return  unless message = @_parse message

    if message.auth is 'ok'
      debug 'got auth ok, ready to go!'
      @emit 'ready'
    else
      debug 'got new message', message
      @emit 'message', message


  _send: (obj) ->

    if @_socket
      @_socket.send JSON.stringify obj
    else
      debug "it's too early to send a message, connect first!"


  _parse: (message) ->

    try
      message = JSON.parse message.data
    catch e
      debug 'got a corrupted message', message
      @close internal = yes
      return null

    return message


  _getAuth: ->

    return {
      auth : {
        clientId  : kookies.get('clientId')
        username  : nick()
        groupName : globals.currentGroup.slug
      }
    }
