WebSocket = require 'ws'
WebSocketServer = require('ws').Server

{EventEmitter} = require 'events'
{Scrubber, Store} = require 'koding-dnode-protocol'
noop = ->


class KiteClient extends EventEmitter
    constructor: (@options, @remoteAddr='ws://localhost:4000/dnode')->
      @localStore = new Store
      @remoteStore = new Store

      self = this
      @api =
        heartbeat: (k)->
          console.log ">>>>>", "heartbeat called", k.withArgs[1]
          remoteFn = k.withArgs[1]
          setInterval ()->
            remoteFn()
          , 1000

    connect: (callback=noop)->
      @ws = new WebSocket @remoteAddr
      self = this
      @ws.on 'open', ()->
        console.log "connected to ", self.remoteAddr
        self.emit 'connected'
        callback(self)

      @ws.on 'message', (data, flags)->
        # now we descrub message and call our callback function
        data = data.replace(/withArgs/ig, 'withArgs')
        scrubbed = JSON.parse data
        scrubber = new Scrubber self.localStore
        unscrubbed = scrubber.unscrub scrubbed, (callbackId)->
          unless self.remoteStore.has(callbackId)
            self.remoteStore.add callbackId, (args...)->
              console.log ".....................", callbackId, args
              self.callRemote callbackId, args

          self.remoteStore.get callbackId

        if self.api.propertyIsEnumerable(scrubbed.method) and 'function' is typeof self.api[scrubbed.method]
          callback = self.api[scrubbed.method]
        else
          callback = self.localStore.get(scrubbed.method)

        if callback
            callback.apply self, unscrubbed

    callRemote: (method, args, authentication, callback=noop)=>
      scrubber = new Scrubber @localStore
      # adding required stuff
      payload = {}
      payload.kite =
        name: @options.name or "application"
        username: "devrim"
        id: "a8877ba5-9b18-420b-792a-e561316b3257"
        environment: 'development'
        region: 'localhost'
        version: "1" # <--- this should always be a string, dont ask me why, its not an integer
        hostname: "aybarss-MacBook-Air.local"
        publicIP:""
        port: @options.port.toString() or null # <-- port should be string.
      payload.withArgs = args
      payload.links = []

      if authentication
        payload.authentication = authentication
      else
        payload.authentication =
          type:"kodingKey",
          key:"NPhFRpZPYuWA4kFA7Y0ewEIQy7qdgj3ij6tegRQ9sd2s-g2-Debdi20fStRiIM5Z"

      scrubber.scrub [payload, callback], =>
        console.log "!!!! 1"
        scrubbed = scrubber.toDnodeProtocol()
        scrubbed.method = method
        console.log "2"
        message = JSON.stringify scrubbed
        console.log "3"
        @ws.send message

    getKites: (callback=noop)->
      @callRemote "getKites",
        "environment": "",
        "hostname": "",
        "id": "",
        "name": "mathworker",
        "region": "",
        "username": "devrim",
        "version": "",
        null,
        (err, kites)->
            callback err, kites

class KiteServer extends EventEmitter
  constructor: ()->
    @_name = @constructor._name
    throw "every worker needs a name" if not @_name? and not @_name
    @localStore = new Store
    @remoteStore = new Store

  callRemote: (client, method, args)=>
      scrubber = new Scrubber @localStore
      # adding required stuff
      payload = args
      scrubber.scrub payload, =>
        console.log "!!!! 1"
        scrubbed = scrubber.toDnodeProtocol()
        scrubbed.method = method
        console.log "2"
        message = JSON.stringify scrubbed
        console.log "3", message
        client.send message

  runServer: (@host="localhost", @port=9999)->
    self = this
    @wss = new WebSocketServer host:@host, port: @port
    @kontrolClient = new KiteClient name:@_name, port: @port
    @kontrolClient.on 'connected', ()=>
      console.log "connecting to kontrol"
      @kontrolClient.callRemote "register", null, null, (err, data)->
        console.log "received data", data
    @kontrolClient.connect()

    @wss.on 'connection', (client)->
      client.on 'message', (data)->
        console.log('received: %s', data)
        #client.send('something')
        data = data.replace(/withArgs/ig, 'withArgs')
        scrubbed = JSON.parse data
        scrubber = new Scrubber self.localStore
        unscrubbed = scrubber.unscrub scrubbed, (callbackId)->
          unless self.remoteStore.has(callbackId)
            self.remoteStore.add callbackId, (args...)->
              console.log ".....................", callbackId, args
              self.callRemote client, callbackId, args
          self.remoteStore.get callbackId

        if self.constructor.prototype.propertyIsEnumerable(scrubbed.method) and 'function' is typeof self[scrubbed.method]
          console.log ">>>", "here is your callback"
          callback = self[scrubbed.method]
        else
          callback = self.localStore.get(scrubbed.method)

        if callback
            callback.apply self, unscrubbed


# server example
class MathWorker extends KiteServer
  @_name = 'mathworker'
  square: (withArgs, callback)->
    console.log "square called !", arguments
    callback null, 1

mathworker = new MathWorker
mathworker.runServer()

# # this is just an example for a client
# k = new KiteClient
# k.on 'connected', ()->
#     console.log "connected...."
#     k.getKites (err, kites)->
#       if err or not Array.isArray(kites) or kites.length == 0
#         throw "no available kite worker"
#       # connecting to first avail kite
#       kite = kites[0]
#       console.log ">>>>", kite.kite.publicIP
#       url = "ws://#{kite.kite.publicIP}:#{kite.kite.port}/dnode"
#       console.log url
#       authentication = 
#         type: 'token'
#         key: kite.token
#       mathworker = new KiteClient url
#       mathworker.on 'connected', ()->
#         setInterval ()->
#           value = Math.random() * 100
#           console.log "sending #{value} to mathworker"
#           mathworker.callRemote "square", value, authentication, (err, data)->
#             console.log "response from mathworker", err, data
#         , 5000
#       mathworker.connect()
# k.connect()