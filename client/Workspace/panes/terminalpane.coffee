class TerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "terminal-pane terminal"

    super options, data

    @createWebTermView()
    @webterm.on "WebTermConnected", (@remote) => @onWebTermConnected()

  createWebTermView: ->
    @webterm           = new WebTermView
      delegate         : this
      cssClass         : "webterm"
      advancedSettings : no

  onWebTermConnected: ->
    {command} = @getOptions()
    @runCommand command if command

  runCommand: (command, callback) ->
    return unless command
    if @remote
      if callback
        @webterm.once "WebTermEvent", callback
        command += ";echo $?|kdevent"
      return @remote.input "#{command}\n"

    if not @remote and not @triedAgain
      @utils.wait 2000, =>
        @runCommand command
        @triedAgain = yes

  pistachio: ->
    """
      {{> @header}}
      {{> @webterm}}
    """