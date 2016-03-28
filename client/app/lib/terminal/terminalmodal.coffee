kd = require 'kd'
KDModalView = kd.ModalView
WebTermView = require './webtermview'


module.exports = class TerminalModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass       = kd.utils.curry 'terminal', options.cssClass
    options.destroyOnExit ?= yes

    if options.machine?.getName? and not options.title
      options.title = "Terminal on #{options.machine.getName()}"

    super options, data

    { machine, command, readOnly } = @getOptions()

    @webterm = new WebTermView {
      delegate: this, machine, readOnly
    }

    @webterm.on 'WebTermEvent', (data) =>
      @emit 'terminal.event', data

    @webterm.once 'WebTermConnected', (remote) =>

      @emit 'terminal.connected', remote

      @on 'terminal.input', (command) =>
        remote.input command
        @webterm.getDomElement().click()

      @run command  if command?

    @webterm.on 'WebTerm.terminated', =>
      @emit 'terminal.terminated'
      @destroy()  if @getOption 'destroyOnExit'

    @on 'click', => @setCss 'zIndex', 10000 + kd.utils.uniqueId()

  viewAppended: ->

    @addSubView @webterm
    @webterm.connectToTerminal()
    @setCss 'zIndex', 10000 + kd.utils.uniqueId()

  run: (command) ->

    @emit 'terminal.input', command + '\n'
