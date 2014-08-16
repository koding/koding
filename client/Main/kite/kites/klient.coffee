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
