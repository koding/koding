kd = require 'kd'
$  = require 'jquery'

PING_URL = 'https://s3.amazonaws.com/koding-ping/ping.json'

class ConnectionChecker extends kd.Object

  @globalNotification = do ->

    notification = null

    show: ->
      notification   ?= new kd.NotificationView
        title         : 'Looks like your Internet connection is down'
        type          : 'tray'
        closeManually : yes
        duration      : 0
        content       : '''
          <p>Koding will continue trying to reconnect but while your
          connection is down, <br>
          no changes you make will be saved back to your VM.
          Please save your work locally as well.</p>
        '''

    hide: ->
      notification?.destroy()
      notification = null


  @listen = ->

    global.connectionCheckerReponse = => @globalNotification.hide()

    global.addEventListener 'online', =>
      @globalNotification.hide()
    , false

    global.addEventListener 'offline', =>
      @globalNotification.show()
    , false

    # Navigator online/offline events are working fine with Chrome
    # but not ok with Safari and Firefox currently. So for FF and Safari
    # we are also initiating traditional ping method to check connection ~ GG
    unless /Chrome/.test global.navigator.userAgent
      kd.utils.repeat 20000, => @ping()


  @ping = (callback = kd.noop) ->

    kallback = (state) =>
      if state is 'online'
        @globalNotification.hide()
        callback()
      else
        @globalNotification.show()

    $.ajax
      url           : PING_URL
      success       : -> kallback 'online'
      jsonpCallback : 'connectionCheckerReponse'
      timeout       : 5000
      dataType      : 'jsonp'
      error         : -> kallback 'offline'


module.exports = ConnectionChecker
