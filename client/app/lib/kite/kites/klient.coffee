Promise = require 'bluebird'
kd = require 'kd'
proxifyTransportUrl = require '../../util/proxifyTransportUrl'


module.exports = class KodingKite_KlientKite extends require('../kodingkite')

  @createApiMapping

    exec               : 'exec'
    ping               : 'kite.ping'
    systemInfo         : 'kite.systemInfo'

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

    webtermKillSessions: 'webterm.killSessions'
    webtermGetSessions : 'webterm.getSessions'
    webtermPing        : 'webterm.ping'

    klientShare        : 'klient.share'
    klientUnshare      : 'klient.unshare'
    klientShared       : 'klient.shared'


  constructor:->

    super

    @terminalSessions = []


  init: ->

    @connect()
    Promise.resolve()


  # setTransport is used to override the setTransport method in KodingKite
  # prior to connection so we can have a custom URL. This is used so Klient
  # Kite can go over our internal userproxy
  setTransport: (@transport) ->

    {url} = @transport.options
    @transport.options.url = proxifyTransportUrl url

    # now call @connect in super, which will connect to our new URL
    super @transport


  disconnect: ->
    super

    kd.singletons.kontrol.kites?.klient?[@getOption 'correlationName'] = null


  webtermConnect: (options)->

    @tell 'webterm.connect', options

      .then (remote) =>

        @addToActiveSessions remote.session

        if @terminalSessions.length is 0
          @fetchTerminalSessions remote.session
        else
          unless remote.session in @terminalSessions
            @terminalSessions.push remote.session

        return remote


  _removeSession: (session)->

    @removeFromActiveSessions session
    @terminalSessions = @terminalSessions.filter (currentSession)->
      session isnt currentSession


  webtermKillSession: (options)->

    {session} = options

    @tell 'webterm.killSession', options

    .then (state) =>

      @_removeSession session
      return state

    .catch (err)=>

      if err.name is 'KiteError' and /No screen session found/i.test err.message
        @_removeSession session

      throw err


  fetchTerminalSessions: (session)->

    return Promise.resolve()  if @_fetchingSessions

    @_fetchingSessions = yes

    @webtermGetSessions()

    .then (sessions)=>

      @terminalSessions = sessions

      if session and session not in @terminalSessions
        @terminalSessions.push session

      @syncSessionsWithLocalStorage()

      @_fetchingSessions = no

    .timeout 10000

    .catch (err)=>

      # Reset current sessions if fails
      if err.message is 'no sessions available'
        @terminalSessions = if session then [session] else []
      else
        @terminalSessions = []

      @_fetchingSessions = no

      @syncSessionsWithLocalStorage()



  getLocalStorage = ->

    return kd.singletons.localStorageController.storage 'Klient', '1.0'

  setActiveSessions = (sessions)->

    getLocalStorage().setValue 'activeSessions', sessions


  getActiveSessions: ->

    return (getLocalStorage().getValue 'activeSessions') ? []


  syncSessionsWithLocalStorage: ->

    setActiveSessions @getActiveSessions().filter (session)=>
      session in @terminalSessions


  addToActiveSessions: (session)->

    activeSessions = @getActiveSessions()
    activeSessions.push session  unless session in activeSessions

    setActiveSessions activeSessions


  removeFromActiveSessions: (session)->

    activeSessions = @getActiveSessions().filter (old)-> session isnt old

    setActiveSessions activeSessions
