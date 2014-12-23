class KodingKite_KlientKite extends KodingKite

  @constructors['klient'] = this

  @createApiMapping

    exec               : 'exec'
    ping               : 'kite.ping'

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

    @connect()  unless @_connectAttempted

    if @terminalSessions.length is 0 and not @_fetchingSessions
    then @fetchTerminalSessions()
    else Promise.resolve()


  # setTransport is used to override the setTransport method in KodingKite
  # prior to connection so we can have a custom URL. This is used so Klient
  # Kite can go over our internal userproxy
  setTransport: (@transport) ->

    {url} = @transport.options
    @transport.options.url = KD.utils.proxifyTransportUrl url

    # now call @connect in super, which will connect to our new URL
    super @transport


  disconnect: ->
    super

    KD.singletons.kontrol.kites?.klient?[@getOption 'correlationName'] = null


  webtermConnect: (options)->

    @tell 'webterm.connect', options

      .then (remote) =>

        unless remote.session in @terminalSessions
          @terminalSessions.push remote.session

        return remote


  webtermKillSession: (options)->

    {session} = options

    @tell 'webterm.killSession', options

      .then (state) =>

        @terminalSessions = @terminalSessions.filter (currentSession)->
          session isnt currentSession

        return state


  fetchTerminalSessions: ->

    @_fetchingSessions = yes

    @webtermGetSessions()

    .then (sessions)=>

      @terminalSessions = sessions
      @_fetchingSessions = no

    .timeout 10000

    .catch (err)=>

      # Reset current sessions if fails
      @terminalSessions = []
      @_fetchingSessions = no
