kd = require 'kd'
Promise = require 'bluebird'
KodingKite = require '../kodingkite'
Klient = require './klient'
nick = require 'app/util/nick'
MemoryFsKite = require './memoryfs'

module.exports = class MemoryFsKlient extends KodingKite

  # implements the same interface with KodingKlientKite
  @api =
    exec                : 'exec'
    ping                : 'kite.ping'
    systemInfo          : 'kite.systemInfo'
    clientSubscribe     : 'client.Subscribe'
    clientUnsubscribe   : 'client.Unsubscribe'
    fsReadDirectory     : 'fs.readDirectory'
    fsGlob              : 'fs.glob'
    fsReadFile          : 'fs.readFile'
    fsGetInfo           : 'fs.getInfo'
    fsSetPermissions    : 'fs.setPermissions'
    fsRemove            : 'fs.remove'
    fsUniquePath        : 'fs.uniquePath'
    fsWriteFile         : 'fs.writeFile'
    fsRename            : 'fs.rename'
    fsMove              : 'fs.move'
    fsCreateDirectory   : 'fs.createDirectory'
    tail                : 'log.tail'
    webtermKillSessions : 'webterm.killSessions'
    webtermGetSessions  : 'webterm.getSessions'
    webtermPing         : 'webterm.ping'
    webtermRename       : 'webterm.rename'
    klientDisable       : 'klient.disable'
    klientInfo          : 'klient.info'
    klientShare         : 'klient.share'
    klientUnshare       : 'klient.unshare'
    klientShared        : 'klient.shared'
    sshKeysAdd          : 'sshkeys.add'

    # extras in klient

    # storageGet { key }
    storageGet          : 'storage.get'
    # storageSet { key, value}
    storageSet          : 'storage.set'
    # storageDelete { key }
    storageDelete       : 'storage.delete'
    # TODO
    webtermConnect      : 'webterm.connect'
    # webtermKillSession { session }
    webtermKillSession  : 'webterm.killSession'


  @createApiMapping @api


  constructor: (options = {}) ->
    options.name = 'mockklient'
    super options


  setTransport: ->

    mockTransport = new MemoryFsKite
      api: MemoryFsKlient.api
      username: nick()

    super mockTransport


  fetchTerminalSessions: -> @transport?.webtermGetSessions?()


  clientSubscribe: (options) -> @transport?.clientSubscribe options
