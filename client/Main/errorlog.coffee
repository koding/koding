class ErrorLog
  @create : KD.utils.throttle 500, (error, params={})->
    {
      kites : {
        os       : {version  : osVersion}
        terminal : {version  : terminalVersion}
      }
      version    : codeVersion
    } = KD.config

    {userAgent} = window.navigator

    error = $.extend {
      error
      terminalVersion
      codeVersion
      userAgent
      useNewKites   : KD.useNewKites
      osKiteVersion : osVersion
    }, params

    KD.remote.api.JErrorLog.create error, ->
