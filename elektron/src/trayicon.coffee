path           = require 'path'
electron       = require 'electron'
{ exec }       = require 'child_process'

Tray           = electron.Tray
Menu           = electron.Menu
{ app, shell, ipcMain } = electron

TRAY_ICON      = path.resolve path.join __dirname, '../assets/icons/kdTemplate.png'
TRAY_ICON_REV  = path.resolve path.join __dirname, '../assets/icons/kdRev.png'
KDCMD          = '/usr/local/bin/kd' # FIXME ~GG
TERMINAL       = 'iTerm'             # FIXME ~GG
CHECK_TIMER    = 120                 # every 2 min.

# Helpers

parseTeam  = (teams) ->

  [ team ] = teams
  team     = team.toLowerCase()
  prefix   = if team is 'koding' then '' else "#{team}."
  teamUrl  = "https://#{prefix}koding.com"

  return { team, teamUrl }

openTerminal = (command) ->

  exec """ osascript <<END
    tell application "#{TERMINAL}" to activate
    tell application "System Events"
      keystroke "n" using {command down}
      keystroke "#{command}"
      key code 52
    end tell
  END
  """

handleOpen = (path, terminal) -> ->

  if terminal
  then openTerminal path
  else shell.openExternal path


module.exports = class KodingTray

  constructor: (mainWindow) ->

    # Globals
    @_mainWindow = mainWindow
    @_inProgress  = no
    @_isKdRunning = no
    @_contextMenu = []
    @_previousTeams = {}

    @tray = new Tray TRAY_ICON
    # @tray.setPressedImage TRAY_ICON_REV

    @tray.on 'click', => @handleClick()

    kallback = =>
      @checkKdStatus no
      @loadPreviousTeams()

    @_mainWindow.webContents.on 'did-navigate', kallback
    @_mainWindow.webContents.on 'did-navigate-in-page', kallback

    setTimeout kallback, 2000
    setInterval kallback, 1000 * CHECK_TIMER



  handleClick: ->

    if @_isKdRunning
    then @tray.popUpContextMenu @_contextMenu
    else @checkKdStatus yes


  setMenu: (menu = [], show = no) ->

    if typeof menu is 'string'
      menu = [ label: menu, enabled: no ]

    menuItems = [
      type    : 'separator'
      visible : @_isKdRunning
    ,
      label   : 'Restart kd...'
      click   : handleOpen 'sudo kd restart', 'terminal'
      visible : @_isKdRunning
      enabled : not @_inProgress
    ,
      label   : 'Refresh'
      click   : => @checkKdStatus yes
      enabled : not @_inProgress
    ,
      type    : 'separator'
    ,
      label   : 'Help'
      click   : handleOpen 'kd help', 'terminal'
    ,
      label   : 'Quit'
      click   : -> app.quit()
    ]

    menuItems = @attachTeamsToMenu menuItems

    @_contextMenu = Menu.buildFromTemplate menu.concat menuItems

    @tray.popUpContextMenu @_contextMenu  if show


  attachTeamsToMenu: (menu) ->

    menu = menu.slice()

    return menu  unless @_previousTeams

    if (keys = Object.keys @_previousTeams).length
      submenu = \
        keys.map (key) =>
          return  if key is 'latest'
          teamName = @_previousTeams[key]
          return { label: teamName, click: -> @_mainWindow.loadURL "https://#{key}.koding.com" }
        .filter(Boolean)

      submenu or= []

      submenu = submenu.concat [
        { type: 'separator', visible: !!submenu.length }
        { label: 'Login to Another Team', click: -> @_mainWindow.loadURL 'https://koding.com/Teams' }
        { label: 'Create a Team', click: -> @_mainWindow.loadURL 'https://koding.com/Teams/Create' }
      ]

      menu.unshift { label: 'Your Teams', submenu }
      menu.unshift { type: 'separator', visible: on }

    return menu


  setFailed: (err) ->

    return  unless err
    @setMenu message = 'Failed to fetch machines'
    console.error message, err
    return  yes



  handleMount: (machine) -> =>

    selectedDir  = electron.dialog.showOpenDialog
      properties : [ 'openDirectory' ]

    return  unless selectedDir

    [ mountTo ] = selectedDir
    remotePath  = "--remotepath /home/#{machine.hostname}"

    @setMenu 'Mount in progress...', yes

    @kd "mount #{machine.vmName} #{mountTo} #{remotePath}", (err, res) =>

      if err
        @setMenu 'Mount failed', yes
        setTimeout @loadMachineMenu, 1000
      else
        @loadMachineMenu()
        do handleOpen mountTo

      console.log 'Mount:', err, res


  handleUnmount: (machine) -> =>

    @setMenu 'Unmount in progress...', yes

    @kd "unmount #{machine.vmName}", (err, res) =>

      if err
        @setMenu 'Unmount failed', yes
        setTimeout @loadMachineMenu, 1000
      else
        @loadMachineMenu()

      console.log 'Unmount:', err, res


  kd: (command, callback) ->

    @_inProgress = yes

    exec "#{KDCMD} #{command}", (err, stdout, stderr) =>

      @_inProgress = no

      return callback err  if err

      if (command.indexOf '--json') > -1
        try
          out = JSON.parse stdout
          callback null, out
        catch e
          callback message: 'Failed to parse:', err: e
      else
        callback null, stdout


  # Machine Fetcher
  loadMachineMenu: (show) ->

    @setMenu 'Fetching machines...'

    @kd 'list --json', (err, result) =>

      return  if @setFailed err

      menu = []

      result = result.filter (machine) -> machine.machineStatus isnt 1

      result.forEach (machine) =>
        # { team, teamUrl } = parseTeam machine.teams
        label = "(#{machine.vmName})"
        label = "#{machine.machineLabel} #{label}"  if machine.machineLabel
        item    = {
          label   : label
          submenu : [
          #   label : "Open #{team}"
          #   click : handleOpen teamUrl
          # ,
          #   type  : 'separator'
          # ,
            label : "Open #{machine.ip}"
            click : handleOpen "http://#{machine.ip}"
          # ,
          #   label : 'Open IDE'
          #   click : handleOpen "#{teamUrl}/IDE/#{machine.machineLabel}/my-workspace"
          ,
            label : 'Open Terminal'
            click : handleOpen "kd ssh #{machine.vmName}", 'terminal'
          ,
            type  : 'separator'
          ]
        }

        if machine.mountedPaths.length > 0
          # assuming that there is currently one mount point per machine
          [ mount ] = machine.mountedPaths
          actions   = [
            label : 'Open folder'
            click : handleOpen "file:///#{mount}"
          ,
            label : 'Unmount'
            click : @handleUnmount machine
          ]
          item.submenu.push
            label   : mount
            submenu : actions
        else
          item.submenu.push
            label   : 'Mount'
            click   : @handleMount machine

        menu.push item

      @setMenu menu, show

  checkKdStatus: (show) ->

    return  if @_inProgress

    @setMenu 'Checking kd ...'

    @kd 'status', (err) =>

      if err
        @setMenu [
          label   : 'kd is not running'
          enabled : no
        ,
          label   : 'Start kd ...'
          click   : handleOpen 'sudo kd start', 'terminal'
        ], no

        @_isKdRunning = no

      else
        @_isKdRunning = yes
        @loadMachineMenu show


  loadPreviousTeams: ->

    ipcMain.once 'answer-previous-teams', (event, previousTeams) =>
      @_previousTeams = previousTeams
      @setMenu()

    @_mainWindow.webContents.send 'get-previous-teams'
