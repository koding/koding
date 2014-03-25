class TerminalKite extends KDKite

  @createApiMapping
    webtermGetSessions: 'webterm.getSessions'
    webtermConnect    : 'webterm.connect'

  @constructors['terminal'] = this