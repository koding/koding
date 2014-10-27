class IDE.TerminalPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass  = 'terminal-pane terminal'
    options.paneType  = 'terminal'
    options.readOnly ?= no

    super options, data

    {@machine} = @getOptions()

    @createTerminal()

  createTerminal: ->
    options =
      delegate         : this
      readOnly         : @getOption 'readOnly'
      machine          : @machine
      mode             : 'create'
      cssClass         : 'webterm'
      advancedSettings : no


    {joinUser, session} = @getOptions()

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

      KD.utils.wait 166, =>
        {path} = @getOptions()
        @runCommand "cd #{path}" if path

    @webtermView.connectToTerminal()

    @webtermView.once "WebTerm.terminated", =>
      paneView = @parent
      tabView  = paneView.parent

      tabView.removePane paneView

  getMode: ->
    return 'create'

  runCommand: (command, callback) ->
    return unless command

    unless @remote
      return new Error 'Could not execute your command, remote is not created'

    if callback
      @webtermView.once 'WebTermEvent', callback
      command += ';echo $?|kdevent'

    @remote.input "#{command}\n"

  notify: (message) -> console.log 'notify:', message

  resurrect: ->
    @destroySubViews()
    @createTerminal()

  setFocus: (state) ->
    super state
    @webtermView.setFocus state


  serialize: ->
    {label, ipAddress, slug, uid} = @machine
    {path, paneType} = @getOptions()

    data       =
      path     : path
      machine  : { label, ipAddress, slug, uid }
      paneType : paneType
      session  : @remote?.session
      hash     : @hash
