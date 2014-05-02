class ErrorLog
  @create :(error, params)->
    {
      kites : {
        os       : {version  : osVersion}
        terminal : {version  : terminalVersion}
        stack    : {newKites : useNewKites}
      }
      version    : codeVersion
    } = KD.config

    error = $.extend {
      error
      osVersion
      terminalVersion
      useNewKites
      codeVersion
    }, params

    KD.remote.api.JErrorLog.create error, ->
