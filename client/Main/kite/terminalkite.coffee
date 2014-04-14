class TerminalKite extends KDKite

  @createApiMapping
    webtermGetSessions: 'webterm.getSessions'
    webtermConnect    : 'webterm.connect'
    webtermKillSession: 'webterm.killSession'
    webtermPing       : 'webterm.ping'

  @constructors['terminal'] = this