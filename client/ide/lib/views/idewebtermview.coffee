kd          = require 'kd'
WebTermView = require 'app/terminal/webtermview'


module.exports = class IDEWebTermView extends WebTermView


  setFocus: (state = yes) ->

    return  if kd.singletons.appManager.frontApp.isChatInputFocused()

    super state
