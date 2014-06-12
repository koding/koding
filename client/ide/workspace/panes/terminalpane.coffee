class IDE.TerminalPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = 'terminal-pane terminal'
    options.paneType = 'terminal'
    options.vm     or= null

    super options, data

  createTerminal: (vm) ->
    @webtermView       = new WebTermView
      cssClass         : 'webterm'
      advancedSettings : no
      delegate         : this
      mode             : @getMode()
      vm               : vm

    @addSubView @webtermView

    @vmOn(vm).then =>
      @webtermView.connectToTerminal()
      @webtermView.on 'WebTermConnected', (@remote) => @emit 'WebtermCreated'

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
      @webtermView.once 'WebTermEvent', callback
      command += ';echo $?|kdevent'

    @remote.input "#{command}\n"

  notify: (message) -> console.log 'notify:', message

  viewAppended: ->
    {vm} = @getOptions()

    if vm then @createTerminal vm
    else
      @fetchVm (err, vm) => @createTerminal vm
