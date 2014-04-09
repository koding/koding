class TerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass  = "terminal-pane terminal"
    options.delay    ?= 0

    super options, data

    @createWebTermView()

  createWebTermView: ->

    KD.singletons.vmController.fetchDefaultVm (err, vm)=>

      @webterm           = new WebTermView {
        cssClass         : "webterm"
        advancedSettings : no
        delegate         : this
        mode             : @getMode()
        vm
      }

      @addSubView @header
      @addSubView @webterm

      @webterm.connectToTerminal()

      @webterm.on "WebTermConnected", (@remote) =>
        @emit "WebtermCreated"
        @onWebTermConnected()

      # WebTermView.setTerminalTimeout null, 15000, handler, handler

  getMode: -> "create"

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

  # pistachio: ->
  #   """
  #     {{> @header}}
  #     {{> @webterm}}
  #   """