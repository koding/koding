kd           = require 'kd'
notification = null

module.exports = copyToClipboard = (el, showNotification = yes) ->

    notification?.destroy()

    kd.utils.selectText el

    msg = 'Copied to clipboard!'

    try
      copied = document.execCommand 'copy'
      throw 'couldn\'t copy'  unless copied
    catch
      key = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'
      msg = "Hit #{key} to copy!"

    return  unless showNotification

    notification = new kd.NotificationView { title: msg }
