class ErrorLog
  @create : do ->
    run = true

    idleUserDetector = new IdleUserDetector
    idleUserDetector.on 'userIdle', -> run = false
    idleUserDetector.on 'userBack', -> run = true

    KD.utils.throttle 500, (error, params={})->
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

      if run
        KD.remote.api.JErrorLog.create error, ->
