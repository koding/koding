electron         = require 'electron'
{ app, ipcMain } = electron

module.exports = class IPCReporter

  MIDDOT = '・'

  constructor: ->

    # Set badge for notification counts
    ipcMain.on 'badge-unread', (e, count = MIDDOT) ->
      app.dock.setBadge count

    ipcMain.on 'badge-reset', ->
      app.dock.setBadge ''
