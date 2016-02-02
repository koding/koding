electron        = require 'electron'
BrowserWindow   = electron.BrowserWindow
ApplicationMenu = require './applicationmenu'
path            = require 'path'

ROOT_URL      = 'http://jarjar.dev.koding.com:8090'

module.exports = ->

  # Create the browser window.
  mainWindow = new BrowserWindow
    width  : 1280
    height : 800
    webPreferences    :
      preload         : path.resolve path.join __dirname, 'noderequire.js'

  # and load the index.html of the app.
  mainWindow.loadURL ROOT_URL

  # Open the DevTools.
  # mainWindow.webContents.openDevTools()

  # Set application menu
  new ApplicationMenu

  # Set badge for notification counts
  electron.app.dock.setBadge '・'

  # Emitted when the window is closed.
  mainWindow.on 'closed', ->
    # Dereference the window object, usually you would store windows
    # in an array if your app supports multi windows, this is the time
    # when you should delete the corresponding element.
    mainWindow = null
