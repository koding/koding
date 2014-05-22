class TerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = 'terminal-pane terminal'

    super options, data

  createWebTermView: ->
    @fetchVm (err, vm) =>
      @addSubView @webterm = new WebTermView
        cssClass           : 'webterm'
        advancedSettings   : no
        delegate           : this
        mode               : @getMode()
        vm                 : vm

      @vmOn(vm).then =>
        @webterm.connectToTerminal()
        @webterm.on 'WebTermConnected', (@remote) => @emit 'WebtermCreated'

  fetchVm: (callback)->
    KD.singletons.vmController.fetchDefaultVm callback

  vmOn: (vm) ->
    osKite = KD.getSingleton('vmController').getKite vm, 'os'
    osKite.vmOn()

  getMode: ->
    return 'create'

  runCommand: (command, callback) ->
    return unless command

    unless @remote
      return new Error 'Could not execute your command, remote is not created'

    if callback
      @webterm.once 'WebTermEvent', callback
      command += ';echo $?|kdevent'

    @remote.input "#{command}\n"

  notify: (message) -> console.log 'notify:', message

  viewAppended: ->
    @createWebTermView()
