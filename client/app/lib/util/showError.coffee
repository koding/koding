kd = require 'kd'

KDNotificationView = kd.NotificationView

fn = (err, messages) ->
  return no  unless err

  if Array.isArray err
    @fn er  for er in err
    return err.length

  if 'string' is typeof err
    message = err
    err     = { message }

  defaultMessages =
    AccessDenied : 'Permission denied'
    KodingError  : 'Something went wrong'

  err.name or= 'KodingError'
  content    = ''

  if messages
    errMessage = messages[err.name] or messages.KodingError \
                                    or defaultMessages.KodingError
  messages or= defaultMessages
  errMessage or= err.message or messages[err.name] or messages.KodingError

  if errMessage?
    if 'string' is typeof errMessage
      title = errMessage
    else if errMessage.title? and errMessage.content?
      { title, content } = errMessage

  duration = errMessage.duration or 2500
  title  or= err.message

  new KDNotificationView { title, content, duration }

  unless err.name is 'AccessDenied'
    kd.warn 'KodingError:', err.message
    kd.error err
  err?


module.exports = fn
