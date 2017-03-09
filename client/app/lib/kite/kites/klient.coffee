kd        = require 'kd'
Promise   = require 'bluebird'
Proxifier = require '../../util/proxifier'


module.exports = class KodingKiteKlientKite extends require('../kodingkite')

  @createApiMapping

    exec               : 'exec'
    ping               : 'kite.ping'
    systemInfo         : 'kite.systemInfo'
    clientSubscribe    : 'client.Subscribe'
    clientUnsubscribe  : 'client.Unsubscribe'
    fsReadDirectory    : 'fs.readDirectory'
    fsGlob             : 'fs.glob'
    fsReadFile         : 'fs.readFile'
    fsGetInfo          : 'fs.getInfo'
    fsSetPermissions   : 'fs.setPermissions'
    fsRemove           : 'fs.remove'
    fsUniquePath       : 'fs.uniquePath'
    fsWriteFile        : 'fs.writeFile'
    fsRename           : 'fs.rename'
    fsMove             : 'fs.move'
    fsCreateDirectory  : 'fs.createDirectory'
    tail               : 'log.tail'
    webtermKillSessions: 'webterm.killSessions'
    webtermGetSessions : 'webterm.getSessions'
    webtermPing        : 'webterm.ping'
    webtermRename      : 'webterm.rename'
    klientDisable      : 'klient.disable'
    klientInfo         : 'klient.info'
    klientShare        : 'klient.share'
    klientUnshare      : 'klient.unshare'
    klientShared       : 'klient.shared'
    sshKeysAdd         : 'sshkeys.add'


  constructor: ->

    super

    @on 'close', (reason) =>

      if reason?.code is 1002

        cc          = kd.singletons.computeController
        machineUId  = @getOption 'correlationName'
        machine     = cc.findMachineFromMachineUId machineUId

        @transport.options.url = @_baseURL  if @_baseURL
        @disconnect()  if not machine or not machine.isRunning()

    @terminalSessions   = []


  # setTransport is used to override the setTransport method in KodingKite
  # prior to connection so we can have a custom URL. This is used so Klient
  # Kite can go over our internal userproxy
  setTransport: (@transport) ->

    { url, checkAlternatives } = @transport.options

    # keep a local copy of proxified version
    Proxifier.proxify { url, checkAlternatives: no }, (newurl) =>

      @_baseURL = newurl

    # ask for the alternatives or proxified version
    Proxifier.proxify { url, checkAlternatives }, (newurl) =>

      @transport.options.url = newurl

      # now call @connect in super, which will connect to our new URL
      super @transport


  disconnect: ->
    super

    kd.singletons.kontrol.kites?.klient?[@getOption 'correlationName'] = null


  webtermConnect: (options) ->

    @tell 'webterm.connect', options

      .then (remote) =>

        @addToActiveSessions remote.session

        if @terminalSessions.length is 0
          @fetchTerminalSessions remote.session
        else
          unless remote.session in @terminalSessions
            @terminalSessions.push remote.session

        return remote


  _removeSession: (session) ->

    @removeFromActiveSessions session
    @terminalSessions = @terminalSessions.filter (currentSession) ->
      session isnt currentSession


  webtermKillSession: (options) ->

    { session } = options

    @tell 'webterm.killSession', options

    .then (state) =>

      @_removeSession session
      return state

    .catch (err) =>

      if err.name is 'KiteError' and /No screen session found/i.test err.message
        @_removeSession session

      throw err


  fetchTerminalSessions: (session) ->

    return Promise.resolve()  if @_fetchingSessions

    @_fetchingSessions = yes

    @webtermGetSessions()

    .then (sessions) =>

      @terminalSessions = sessions

      if session and session not in @terminalSessions
        @terminalSessions.push session

      @syncSessionsWithLocalStorage()

      @_fetchingSessions = no

    .timeout 15000

    .catch (err) =>

      # Reset current sessions if fails
      if err.message is 'no sessions available'
        @terminalSessions = if session then [session] else []
      else
        @terminalSessions = []

      @_fetchingSessions = no

      @syncSessionsWithLocalStorage()


  storageSet: (key, value) ->

    if not key or not value
      return  Promise.reject 'key and value required'

    value = (JSON.stringify value) or ''

    @tell 'storage.set', { key, value }

  # Queueing is required for client side calls to get requests
  # in order correctly. So if you need to set different value
  # for the same key all the time it's better to use this
  # setter instead of ::storageSet ~ GG

  # Detailed explanation can be found at
  # https://github.com/koding/koding/pull/3372#discussion_r28312666

  storageSetQueued: do (queue = []) ->

    locked = no

    (key, value) ->

      if not key or not value
        return  Promise.reject 'key and value required'

      value = (JSON.stringify value) or ''

      consume = =>

        return  if queue.length is 0 or locked
        locked = yes

        { key, value, resolve, reject } = queue.shift()

        @tell 'storage.set', { key, value }

          .then (res) ->
            locked = no
            consume()
            resolve res
            return res

          .catch (err) ->
            locked = no
            consume()
            reject err

      new Promise (resolve, reject) ->
        queue.push { key, value, resolve, reject }
        consume()  if queue.length is 1


  storageGet: (key) ->

    return  Promise.reject 'key required'  unless key

    @tell 'storage.get', { key }

    .then (value) ->
      try value = JSON.parse value
      return value
    .catch (err) ->
      return null


  storageDelete: (key) ->

    return  Promise.reject 'key required'  unless key

    @tell 'storage.delete', { key }


  setActiveSessions: (sessions) ->
    @storageSet 'activeSessions', sessions


  getActiveSessions: ->

    @storageGet 'activeSessions'
    .then (sessions) -> sessions or []
    .catch          -> []


  syncSessionsWithLocalStorage: ->

    @getActiveSessions().then (sessions) =>
      @setActiveSessions sessions.filter (session) =>
        session in @terminalSessions


  addToActiveSessions: (session) ->

    @getActiveSessions().then (activeSessions) =>
      activeSessions.push session  unless session in activeSessions
      @setActiveSessions activeSessions


  removeFromActiveSessions: (session) ->

    @getActiveSessions().then (sessions) =>
      @setActiveSessions sessions.filter (old) -> session isnt old
