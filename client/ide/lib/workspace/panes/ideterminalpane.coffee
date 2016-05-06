kd              = require 'kd'
nick            = require 'app/util/nick'
IDEWebTermView  = require '../../views/idewebtermview'
IDEPane         = require './idepane'
FSHelper        = require 'app/util/fs/fshelper'

module.exports = class IDETerminalPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass  = 'terminal-pane terminal unfocused'
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

    @webtermView = new IDEWebTermView options

    @addSubView @webtermView

    @webtermView.on 'WebTermConnected', (remote) =>
      @remote  = remote
      @session = remote.session  unless @session
      @emit 'WebtermCreated'
      @emit 'ready'

      kd.utils.wait 166, =>
        { path, command } = @getOptions()
        return @runCommand "cd #{FSHelper.escapeFilePath path}"  if path
        return @runCommand command  if command

    @webtermView.connectToTerminal()

    @webtermView.once 'WebTerm.terminated', =>

      return  unless @parent

      paneView = @parent
      tabView  = paneView.parent

      tabView.removePane paneView

      @machine.getBaseKite().fetchTerminalSessions()

    @on 'RealtimeManagerSet', =>
      return  if @rtm.isDisposed
      myPermission = @rtm.getFromModel('permissions').get nick()
      @makeReadOnly()  if myPermission is 'read'


  getMode: ->

    return  if @session? then 'shared' else 'create'


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

    classToSet   = if state then 'focused' else 'unfocused'
    classToUnset = if state then 'unfocused' else 'focused'
    @setClass classToSet
    @unsetClass classToUnset

    @webtermView.setFocus state
    kd.singletons.mainView.setKeyView null  if state


  serialize: ->

    data       =
      paneType : @getOptions().paneType
      session  : @remote?.session
      hash     : @hash

    return data


  setEditMode: (state) ->

    { terminal } = @webtermView
    return  unless terminal

    { cursor } = terminal
    return  unless cursor

    if state
      @webtermView.terminal.isReadOnly = no
      cursor.stopped = no
      cursor.setBlinking yes
    else
      @webtermView.terminal.isReadOnly = yes
      cursor.stopBlink()


  makeEditable: -> @ready => @setEditMode yes


  makeReadOnly: -> @ready => @setEditMode no


  setSession: (session) ->

    @session = session
    @remote?.session = session
