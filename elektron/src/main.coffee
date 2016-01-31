electron      = require 'electron'
start         = require './start'
app           = electron.app

# Report crashes to our server.
electron.crashReporter.start
  productName : 'Koding'
  companyName : 'Koding, Inc.'
  submitURL   : 'https://koding.com/-/crashReport',
  autoSubmit  : true

# Quit when all windows are closed.
app.on 'window-all-closed', ->
  # On OS X it is common for applications and their menu bar
  # to stay active until the user quits explicitly with Cmd + Q
  app.quit()  if process.platform isnt 'darwin'


app.on 'ready', start
