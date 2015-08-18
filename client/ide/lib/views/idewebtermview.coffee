kd          = require 'kd'
WebTermView = require 'app/terminal/webtermview'


module.exports = class IDEWebTermView extends WebTermView


  setFocus: (state = yes) ->

    return  if kd.singletons.appManager.frontApp.isChatInputFocused?()

    super state


  viewAppended: ->

    super

    kd.utils.wait 400, => @triggerFitToWindow()  if @getOption('mode') is 'shared'

