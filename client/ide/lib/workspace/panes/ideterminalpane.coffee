kd = require 'kd'
nick = require 'app/util/nick'
WebTermView = require 'app/terminal/webtermview'
IDEPane = require './idepane'
FSHelper = require 'app/util/fs/fshelper'

module.exports = class IDETerminalPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass  = 'terminal-pane terminal'
    options.paneType  = 'terminal'
    options.readOnly ?= no

    super options, data

    { @machine, @session } = @getOptions()

    @createTerminal()


  createTerminal: ->

    options =
      delegate         : this
      readOnly         : @getOption 'readOnly'
      machine          : @machine
      mode             : @getMode()
      session          : @session
      cssClass         : 'webterm'
      advancedSettings : no

    { joinUser, session } = @getOptions()

    if joinUser and session
      # TODO: Also pass sizeX and sizeY
      options.joinUser = joinUser
      options.session  = session
      options.mode     = 'shared'

    @webtermView = new WebTermView options

    @addSubView @webtermView

    @webtermView.on 'WebTermConnected', (remote) =>
      @remote = remote
      @emit 'WebtermCreated'

      kd.utils.wait 166, =>
        {path} = @getOptions()
        return  unless path
        @runCommand "cd #{FSHelper.escapeFilePath path}"

    @webtermView.connectToTerminal()

    @webtermView.once "WebTerm.terminated", =>

      return  unless @parent

      paneView = @parent
      tabView  = paneView.parent

      tabView.removePane paneView

      @machine.getBaseKite().fetchTerminalSessions()

    @once 'RealtimeManagerSet', =>
      return  if @rtm.isDisposed
      myPermission = @rtm.getFromModel('permissions').get nick()
      @makeReadOnly()  if myPermission is 'read'


  getMode: ->

    return  if @session? then 'resume' else 'create'


  runCommand: (command, callback) ->

    return unless command

    unless @remote
      return new Error 'Could not execute your command, remote is not created'

    if callback
      @webtermView.once 'WebTermEvent', callback
      command += ';echo $?|kdevent'

    @remote.input "#{command}\n"


  resurrect: ->

    @destroySubViews()
    @createTerminal()


  setFocus: (state) ->

    super state
    @webtermView.setFocus state
    kd.singletons.mainView.setKeyView null  if state


  serialize: ->

    data       =
      paneType : @getOptions().paneType
      session  : @remote?.session
      hash     : @hash

    return data


  setEditMode: (state) ->

    {terminal} = @webtermView
    return  unless terminal

    {cursor} = terminal
    return  unless cursor

    if state
      @webtermView.terminal.isReadOnly = no
      cursor.stopped = no
      cursor.setBlinking yes
    else
      @webtermView.terminal.isReadOnly = yes
      cursor.stopBlink()


  makeEditable: -> @setEditMode yes


  makeReadOnly: -> @setEditMode no
