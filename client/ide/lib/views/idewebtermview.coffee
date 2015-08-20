kd          = require 'kd'
WebTermView = require 'app/terminal/webtermview'


module.exports = class IDEWebTermView extends WebTermView


  setFocus: (state = yes) ->

    return  if kd.singletons.appManager.frontApp.isChatInputFocused?()

    super state


  viewAppended: ->

    super

    # Call the "triggerFitToWindow" when terminal is connected.
    if @getOption('mode') is 'shared'
      @on 'WebTermConnected', =>
        @triggerFitToWindow()
