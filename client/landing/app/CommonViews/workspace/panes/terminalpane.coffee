class TerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass  = "terminal-pane"
    options.delay    ?= if location.hostname is "localhost" then 10000 else 10000

    super options, data

    @container = new KDView
      cssClass : "tw-terminal-splash"
      partial  : "<p>Preparing your VM...</p>"

    # we need to wait vm startup for guest users
    KD.utils.wait options.delay, =>
      @createWebTermView()
      @webterm.on "WebTermConnected", (@remote) =>
        @emit "WebtermCreatead"
        @onWebTermConnected()

      @container.destroy()
      @addSubView @webterm

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
      {{> @container}}
    """