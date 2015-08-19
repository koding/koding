kd          = require 'kd'
WebTermView = require 'app/terminal/webtermview'


module.exports = class IDEWebTermView extends WebTermView


  setFocus: (state = yes) ->

    return  if kd.singletons.appManager.frontApp.isChatInputFocused?()

    super state


  viewAppended: ->

    super

    if @getOption('mode') is 'shared'

      # Execute it after 400ms. Because it needs to wait dom changes.
      kd.utils.wait 400, =>
        @triggerFitToWindow()

