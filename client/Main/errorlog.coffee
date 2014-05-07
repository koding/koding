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

    {userAgent} = window.navigator

    error = $.extend {
      error
      osKiteVersion
      terminalVersion
      useNewKites
      codeVersion
      userAgent
    }, params

    KD.remote.api.JErrorLog.create error, ->
