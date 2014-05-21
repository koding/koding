class ErrorLog
  @create : do ->
    idle = false

    idleUserDetector = new IdleUserDetector
    idleUserDetector.on 'userIdle', -> idle = true
    idleUserDetector.on 'userBack', -> idle = false

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
        idle
        useNewKites   : KD.useNewKites
        osKiteVersion : osVersion
      }, params

      KD.remote.api.JErrorLog.create error, ->
