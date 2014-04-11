class TerminalKite extends KDKite

  @createApiMapping
    webtermGetSessions: 'webterm.getSessions'
    webtermConnect    : 'webterm.connect'
    webtermKillSession: 'webterm.killSession'

  @constructors['terminal'] = this