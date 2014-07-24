class IDE.TerminalPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass  = 'terminal-pane terminal'
    options.paneType  = 'terminal'
    options.readOnly ?= no

    super options, data

    {@machine} = @getOptions()

    @createTerminal()

  createTerminal: ->
    @webtermView       = new WebTermView
      delegate         : this
      readOnly         : @getOption 'readOnly'
      machine          : @machine
      mode             : @getMode()
      cssClass         : 'webterm'
      advancedSettings : no

    @addSubView @webtermView

    @webtermView.on 'WebTermConnected', (remote) =>
      @remote = remote
      @emit 'WebtermCreated'

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

  viewAppended: ->

    super

    @webtermView.connectToTerminal()
