class ErrorLog
  @create : do ->
    idle = false

    idleUserDetector = new IdleUserDetector
    idleUserDetector.on 'userIdle', -> idle = true
    idleUserDetector.on 'userBack', -> idle = false

    KD.utils.throttle 500, (error, params={})->
      return  unless KD.config.logToInternal

      {
        kites : {
          os       : {version  : osVersion}
          terminal : {version  : terminalVersion}
        }
        version    : codeVersion
      } = KD.config

      {userAgent} = window.navigator
      {protocol}  = KD.remote.mq.ws

      error = $.extend {
        error
        terminalVersion
        codeVersion
        userAgent
        idle
        protocol
        useNewKites   : yes
        osKiteVersion : osVersion
      }, params

      KD.remoteLog.api.JErrorLog.create error, ->
