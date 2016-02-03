electron = require 'electron'
Menu     = require 'menu'
app      = electron.app

module.exports = class ApplicationMenu

  constructor: ->

    menu = Menu.buildFromTemplate @getMenu()
    Menu.setApplicationMenu menu


  getMenu: ->

    applicationMenu = [
      label: 'Help'
      submenu: [
        label: 'Koding.com'
        click: ->
      ,
        label: 'Documentation'
        click: ->
      ]
    ]

    return applicationMenu  unless process.platform is 'darwin'

    applicationMenu.unshift
      label: 'Koding'
      submenu: [
        label: "About Koding"
        role: 'about'
      ,
        type: 'separator'
      ,
        label: 'Check for updates'
        role: 'update'
        submenu: []
      ,
        type: 'separator'
      ,
        label: "Hide Koding"
        accelerator: 'Command+H'
        role: 'hide'
      ,
        label: 'Hide Others'
        accelerator: 'Command+Shift+H'
        role: 'hideothers'
      ,
        label: 'Show All'
        role: 'unhide'
      ,
        type: 'separator'
      ,
        label: 'Quit'
        accelerator: 'Command+Q'
        click: -> app.quit()
      ]

    return applicationMenu
