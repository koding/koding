electron        = require 'electron'
shell           = require 'shell'
BrowserWindow   = electron.BrowserWindow
ApplicationMenu = require './applicationmenu'
IPCReporter     = require './ipcreporter'
path            = require 'path'

# temp
# get this from config or runtime options - SY
ROOT_URL = 'https://koding.com/Teams'

module.exports = ->

  # Create the browser window.
  mainWindow = new BrowserWindow
    width             : 1280
    height            : 800
    title             : 'Koding for Teams'
    show              : yes
    acceptFirstMouse  : yes
    backgroundColor   : '#131313'
    webPreferences    :
      partition       : 'persist:koding'
      preload         : path.resolve path.join __dirname, 'noderequire.js'
      nodeIntegration : no

  # and load the index.html of the app.
  mainWindow.loadURL ROOT_URL

  # Open the DevTools.
  # mainWindow.webContents.openDevTools()

  # Set application menu
  new ApplicationMenu

  # Start listening the web app
  new IPCReporter

  # Emitted when the window is closed.
  mainWindow.on 'closed', ->
    # Dereference the window object, usually you would store windows
    # in an array if your app supports multi windows, this is the time
    # when you should delete the corresponding element.
    mainWindow = null

  mainWindow.webContents.on 'new-window', (e, url) ->
    e.preventDefault()
    shell.openExternal url
