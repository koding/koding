kd = require 'kd'

module.exports = class VideoControlView extends kd.ButtonView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'solid', options.cssClass
    options.icon = yes
    super options, data

    @setActiveState options.active


  click: (event) ->

    kd.utils.stopDOMEvent event
    @setActiveState state = not @active
    @emit 'ActiveStateChangeRequested', state


  setActiveState: (active) ->

    if active
    then @setClass 'is-active'
    else @unsetClass 'is-active'

    @active = active





