kd = require 'kd'
KDBlockingModalView = kd.BlockingModalView
KDNotificationView = kd.NotificationView
nick = require 'app/util/nick'
FSHelper = require 'app/util/fs/fshelper'

module.exports = (nodeView) ->

  notification     = null
  vmController     = kd.getSingleton "vmController"
  plainPath        = FSHelper.plainPath nodeView.getData().path
  isFolder         = nodeView.getData().type is "folder"
  timestamp        = Date.now()
  tmpFileName      = if isFolder then "tmp#{timestamp}.zip" else "tmp#{timestamp}"
  relativePath     = "/home/#{nick()}/Web/#{tmpFileName}"

  removeTempFile   = ->
    vmController.run
      withArgs: "rm #{relativePath}"
      vmName  : nodeView.getData().vmName

  runCommand = (command) ->
    vmController.run
      withArgs   : command
      vmName     : nodeView.getData().vmName
    , (err, res)->
      if err or res.exitStatus > 0
        notification.notificationSetTitle "An error occurred. Please try again."
        notification.notificationSetTimer 4000
        notification.setClass "error"
      else
        notification.hide()
        kallback()

  kallback = ->
    modal          = new KDBlockingModalView
      title        : "Upload to Dropbox"
      cssClass     : "modal-with-text"
      content      : "<p>Zipping your content is done. Click \"Choose Folder\" button to choose a folder on your Dropbox to start upload.</p>"
      overlay      : yes
      buttons      :
        "Choose"   :
          title    : "Choose Folder"
          style    : "solid green medium"
          callback : =>
            modal.destroy()
            fileName     = FSHelper.getFileNameFromPath plainPath
            fileName     = "#{fileName}.zip"  if isFolder
            options      =
              files      : [
                filename : fileName
                url      : "http://#{kd.getSingleton('vmController').defaultVmName}/#{tmpFileName}"
              ]
              success: ->
                notification.notificationSetTitle "Your file has been uploaded."
                notification.notificationSetTimer 4000
                notification.setClass "success"
                removeTempFile()
              error: ->
                notification.notificationSetTitle "An error occurred while uploading your file."
                notification.notificationSetTimer 4000
                notification.setClass "error"
                removeTempFile()
              cancel: ->
                removeTempFile()
                notification.destroy()
              progress: (progress) ->
                notification.notificationSetTitle "Uploading to Dropbox - #{progress * 100}% done..."
                notification.show()

            Dropbox.save options

        Cancel     :
          style    : "solid light-gray medium"
          callback : ->
            modal.destroy()
            removeTempFile()

  command   = "mkdir -p Web ; cp #{plainPath} #{relativePath}"
  title     = "Uploading your file..."

  if isFolder
    command = "mkdir -p Web ; zip -r #{relativePath} #{plainPath}"
    title   = "Zipping your folder..."

  notification = new KDNotificationView
    title      : title
    type       : "mini"
    duration   : 120000

  runCommand command
