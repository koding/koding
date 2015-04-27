kd = require 'kd'

module.exports = class VideoControlView extends kd.ButtonView

  constructor: (options = {}, data) ->

    options.tooltip  = yes
    options.cssClass = kd.utils.curry 'solid', options.cssClass
    options.icon     = yes

    options.activeTooltipText   or= ''
    options.deactiveTooltipText or= ''

    super options, data

    @setActiveState options.active


  setTooltip: ->

    { activeTooltipText, deactiveTooltipText } = @getOptions()
    options =
      title: if @active then activeTooltipText else deactiveTooltipText
      placement: 'left'

    super options


  click: (event) ->

    kd.utils.stopDOMEvent event
    @setActiveState state = not @active
    @emit 'ActiveStateChangeRequested', state


  setActiveState: (active) ->

    if active
    then @setClass 'is-active'
    else @unsetClass 'is-active'

    @active = active

    @setTooltip()


