kd           = require 'kd'
notification = null

module.exports = copyToClipboard = (el, showNotification = yes) ->

  notification?.destroy()

  kd.utils.selectText el

  msg = 'Copied to clipboard!'

  try
    copied = document.execCommand 'copy'
    couldntCopy = 'couldn\'t copy'
    throw couldntCopy  unless copied
  catch
    key = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'
    msg = "Hit #{key} to copy!"

  return  unless showNotification

  notification = new kd.NotificationView { title: msg }
