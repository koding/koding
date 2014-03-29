class KodingKite_TerminalKite extends KodingKite_VmKite

  @constructors['terminal'] = this
  
  @createApiMapping
    webtermGetSessions: 'webterm.getSessions'
    webtermConnect    : 'webterm.connect'
