debug = require('debug') 'app:nodenotification'

kd = require 'kd'

SockJS = require 'sockjs-client'
backoff = require 'backoff'

kookies = require 'kookies'
isLoggedIn = require 'app/util/isLoggedIn'


module.exports = class NodeNotificationClient extends kd.Object

  SUBSCRIBE_ENDPOINT = '/notify/subscribe' # this can be taken from config ~ GG
  [ AUTH, MESSAGE, OK ] = ['auth', 'message', 'ok']


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

    return  unless isLoggedIn()

    @_bo.on 'ready', =>
      @_socket?.close()
      delete @_socket
      @_connect()

    @_bo.backoff()


  _connect: ->

    debug 'initiating the socket connection...'
    @_socket = new SockJS SUBSCRIBE_ENDPOINT

    @_socket.addEventListener 'message', @bound '_handleNewMessage'
    @_socket.addEventListener 'close',   @bound '_handleClose'
    @_socket.addEventListener 'error',   @bound '_handleError'
    @_socket.addEventListener 'open',    @bound '_handleOpen'

    return this


  close: (internal = no) ->

    debug 'closing the connection'
    @_socket?.close()


  _handleOpen: ->

    debug 'connection established, sending auth message...'
    @_send @_getAuth()

    # if it ends up with connecting to sockjs server and sending the message
    # sometimes we encountered no response issue that just happens. to prevent
    # possible race condition here we're waiting for 5 sec. and checking for
    # the connection status again. otherwise backoff is handling retry part ~GG
    kd.utils.wait 5000, =>
      @_bo.backoff()  unless @readyState


  _handleClose: (event) ->

    debug 'connection closed by remote.'

    # this is due to readyState implementation in kd.Object ~ GG
    @readyState = 0
    @once 'ready', => @readyState = 1

    # if connection is closed on request (calling ::close) or if it's closed
    # by remote which can happen when there is an authentication error occurs
    # we don't need to retry to reconnect which can be identified as in
    # CloseEvent.code [1] (1000) for the all other cases if code is greater
    # than 1000 we'll retry ~ GG
    #
    # [1] https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent
    @_bo.backoff()  if event?.code > 1000


  _handleError: (error) ->
    debug 'got an error', error


  _handleNewMessage: (message) ->

    return  unless message = @_parse message

    if message.type is AUTH and message.status is OK
      debug 'got auth ok, ready to go!'
      @emit 'ready'

    else if message.type is MESSAGE

      if user = message.recipient.user
        debug "got new message for #{user} user", message
        to = 'message'
      else
        debug "got new message for #{message.recipient.group} group", message
        to = 'group:message'

      @emit to, message.content


  _send: (obj) ->

    @_socket.send JSON.stringify obj


  _parse: (message) ->

    try
      message = JSON.parse message.data
    catch e
      debug 'got a corrupted message, dropping to the floor', message, e
      return null

    return message


  _getAuth: ->

    return {
      auth: {
        clientId: kookies.get 'clientId'
      }
    }
