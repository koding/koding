electron       = require 'electron'
Menu           = electron.Menu
{ app, shell } = electron

module.exports = class ApplicationMenu

  constructor: ->

    menu = Menu.buildFromTemplate @getMenu()
    Menu.setApplicationMenu menu


  getMenu: ->

    applicationMenu = [
      label: 'Edit'
      submenu: [
        { label: 'Undo', accelerator: 'CmdOrCtrl+Z', selector: 'undo:' }
        { label: 'Redo', accelerator: 'Shift+CmdOrCtrl+Z', selector: 'redo:' }
        { type: 'separator' }
        { label: 'Cut', accelerator: 'CmdOrCtrl+X', selector: 'cut:' }
        { label: 'Copy', accelerator: 'CmdOrCtrl+C', selector: 'copy:' }
        { label: 'Paste', accelerator: 'CmdOrCtrl+V', selector: 'paste:' }
        { label: 'Select All', accelerator: 'CmdOrCtrl+A', selector: 'selectAll:' }
      ]
    ,
      label: 'View'
      submenu: [
        label: 'Reload'
        accelerator: 'CmdOrCtrl+R'
        click: (item, focusedWindow) ->
          focusedWindow.reload()  if focusedWindow
      ,
        label: 'Toggle Full Screen'
        accelerator: do ->
          if (process.platform is 'darwin')
            return 'Ctrl+Command+F'
          else
            return 'F11'
        click: (item, focusedWindow) ->
          focusedWindow.setFullScreen not focusedWindow.isFullScreen()  if focusedWindow
      ,
        label: 'Toggle Developer Tools'
        accelerator: do ->
          if process.platform is 'darwin'
          then 'Alt+Command+I'
          else 'Ctrl+Shift+I'
        click: (item, focusedWindow) ->
          focusedWindow.toggleDevTools()  if (focusedWindow)
      ]
    ,
      label: 'Help'
      submenu: [
        label: 'Koding.com'
        click: -> shell.openExternal 'https://www.koding.com'
      ,
        label: 'Documentation'
        click: -> shell.openExternal 'https://www.koding.com/Docs'
      ]
    ]

    return applicationMenu  unless process.platform is 'darwin'

    applicationMenu.unshift
      label: 'Koding'
      submenu: [
        label: 'About Koding'
        role: 'about'
      ,
        type: 'separator'
      # ,
      #   label: 'Check for updates'
      #   role: 'update'
      #   submenu: []
      ,
        type: 'separator'
      ,
        label: 'Minimize Koding'
        accelerator: 'Command+M'
        role: 'minimize'
      ,
        label: 'Hide Koding'
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
