kd = require 'kd'
KDModalView = kd.ModalView
KDView = kd.View
WebTermView = require '../terminal/webtermview'


# # Example Code

# modal = new ModalViewWithTerminal
#     title: "nadssadsa"
#     content: "asdadsa"
#     terminal:
#         command: ""
#         hidden: true
#     buttons:
#         "Hello":
#             cssClass: "solid light-gray medium"
#             callback: -> modal.showTerminal()
#
# modal.on "terminal.event", (data) ->
#     alert data
#
# modal.on "terminal.terminated", ->
#     modal.destroy()

module.exports = class ModalViewWithTerminal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'terminal', options.cssClass

    super options, data

    { @terminal } = options

    @terminal        or= {}
    @terminal.height or= 200
    @terminal.screen or= no

    @on 'terminal.connected', (remote) =>
      @on 'terminal.input', (command) =>
        remote.input command
        @webterm.$().click()

      @run @terminal.command  if @terminal.command and not @hidden

    terminalWrapper = new KDView
      cssClass : 'modal-terminal-wrapper'
      noScreen : not @terminal.screen
      vmName   : @terminal.vmName

    @createWebTermView terminalWrapper

    @hidden = @terminal.hidden ? no
    # webterm crashes when its hidden, so we hide it using height: 0
    terminalWrapper.$().css 'height', if @hidden then 0 else @terminal.height

    @webterm.on 'WebTermEvent',     (data)    => @emit 'terminal.event', data
    @webterm.on 'WebTermConnected', (remote)  => @emit 'terminal.connected', remote
    @webterm.on 'WebTerm.terminated',         => @emit 'terminal.terminated'
    terminalWrapper.addSubView @webterm

    @addSubView terminalWrapper

  createWebTermView: (terminalWrapper) ->

    @webterm           = new WebTermView
      delegate         : terminalWrapper
      cssClass         : 'webterm'
      advancedSettings : no
    @webterm.connectToTerminal()

  run: (command) ->
    if @hidden
      @showTerminal =>
        @input command
    else
      @input command

  input: (command) ->
    @emit 'terminal.input', command + '\n'

  hideTerminal: ->
    @hidden = yes
    @webterm.getDelegate().$().animate { height: 0 }, 100, =>
      @setPositions()

  showTerminal: (callback) ->
    @hidden = no
    @webterm.getDelegate().$().animate { height: @terminal.height }, 100, =>
      @setPositions()
      @run @terminal.command  if @terminal.command
      @webterm.$().click()
      callback?()

  toggleTerminal: (callback) ->
    @[if @hidden then 'showTerminal' else 'hideTerminal'] callback
