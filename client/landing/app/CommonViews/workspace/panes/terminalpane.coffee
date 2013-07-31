class TerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "terminal-pane"

    super options, data

    @createWebTermView()
    @webterm.on "WebTermConnected", (@remote) => @onWebTermConnected()

  createWebTermView: ->
    @webterm           = new WebTermView
      delegate         : @
      cssClass         : "webterm"
      advancedSettings : no

  onWebTermConnected: ->
    {command} = @getOptions()
    @runCommand command if command

  runCommand: (command) ->
    return unless command
    return @remote.input "#{command}\n"  if @remote

    if not @remote and not @triedAgain
      @utils.wait 2000, =>
        @runCommand command
        @triedAgain = yes

  pistachio: ->
    """
      {{> @header}}
      {{> @webterm}}
    """