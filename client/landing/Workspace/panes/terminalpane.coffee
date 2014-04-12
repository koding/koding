class TerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass  = "terminal-pane terminal"
    options.delay    ?= 0

    super options, data

    @createWebTermView()

  createWebTermView: ->

    @fetchVm (err, vm) =>

      @webterm           = new WebTermView {
        cssClass         : "webterm"
        advancedSettings : no
        delegate         : this
        mode             : @getMode()
        vm
      }

      @addSubView @header
      @addSubView @webterm

      @vmOn(vm).then =>

        @webterm.connectToTerminal()

        @webterm.on "WebTermConnected", (@remote) =>
          @emit "WebtermCreated"
          @onWebTermConnected()

  notify: (message) -> console.log "notify:", message

  fetchVm: (callback)->
    KD.singletons.vmController.fetchDefaultVm callback

  vmOn: (vm) ->
    { vmController } = KD.singletons

    osKite = vmController.getKite vm, 'os'
    osKite.vmOn()

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
