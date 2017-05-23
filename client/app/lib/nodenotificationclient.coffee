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

    @on 'ready', ->
      debug 'connected and verified, listening for new events...'


  connect: ->

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


  _handleClose: ->

    debug 'connection closed by remote.'
    console.log '_handleClose', arguments


  _handleNewMessage: (message) ->

    return  unless message = @_parse message

    if message.auth is 'ok'
      debug 'got auth ok, ready to go!'
      @emit 'ready'
    else
      debug 'an unknown message received', message


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
