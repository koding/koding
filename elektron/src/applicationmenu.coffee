electron = require 'electron'
Menu     = require 'menu'
app      = electron.app

module.exports = class ApplicationMenu

  constructor: ->

    menu = Menu.buildFromTemplate @getMenu()
    Menu.setApplicationMenu menu


  getMenu: ->

    applicationMenu = [
      label: "Edit"
      submenu: [
        { label: "Undo", accelerator: "CmdOrCtrl+Z", selector: "undo:" }
        { label: "Redo", accelerator: "Shift+CmdOrCtrl+Z", selector: "redo:" }
        { type: "separator" }
        { label: "Cut", accelerator: "CmdOrCtrl+X", selector: "cut:" }
        { label: "Copy", accelerator: "CmdOrCtrl+C", selector: "copy:" }
        { label: "Paste", accelerator: "CmdOrCtrl+V", selector: "paste:" }
        { label: "Select All", accelerator: "CmdOrCtrl+A", selector: "selectAll:" }
      ]
    ,
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
