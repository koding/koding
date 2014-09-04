class KodingKite_KlientKite extends KodingKite

  @constructors['klient'] = this

  @createApiMapping

    exec               : 'exec'

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

    webtermGetSessions : 'webterm.getSessions'
    webtermConnect     : 'webterm.connect'
    webtermKillSession : 'webterm.killSession'
    webtermPing        : 'webterm.ping'

  init: ->
    @connect()
    Promise.resolve()

  # setTransport is used to override the setTransport method in KodingKite
  # prior to connection so we can have a custom URL. This is used so Klient
  # Kite can go over our internal userproxy
  setTransport: (@transport) ->
    # let's use DOM for parsing the url
    parser = document.createElement("a")
    parser.href = @transport.options.url

    # build our new url, example:
    # old: http://54.164.174.218:3000/kite
    # new: https://koding.com/-/userproxy/54.164.243.111/kite
    #           or
    #      http://localhost:8090/-/userproxy/54.164.243.111/kite

    {hostname, protocol, port} = document.location

    changedUrl = "#{protocol}//#{hostname}#{if port then ":#{port}" else ""}/-/userproxy/#{parser.hostname}/kite"

    @transport.options.url = changedUrl

    # now call @connect in super, which will connect to our new URL
    super transport


  disconnect: ->

    super

    KD.singletons.kontrol.kites?.klient?[@getOption 'correlationName'] = null
