kd = require 'kd'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
showNotification = require './showNotification'
Encoder = require 'htmlencode'

module.exports = showError = (err) ->
  return no  unless err

  if Array.isArray err
    @fn er  for er in err
    return err.length

  message = 'Something went wrong!'
  notification = {}

  defaultMessages =
    AccessDenied : 'Permission denied'
    KodingError  : 'Something went wrong'

  err.name or= 'KodingError'

  if 'string' is typeof err
    message = err
    err = { message }
  else if 'object' is typeof err
    message = err.message or defaultMessages[err.name] or message


  notification.type               = 'caution'
  notification.content            = Encoder.htmlDecode message
  notification.primaryButtonTitle = 'OK'

  showNotification notification

  unless err.name is 'AccessDenied'
    kd.warn 'KodingError:', err.message
    kd.error err
    sendDataDogEvent 'ApplicationError', { prefix: 'app-error' }

  return yes
