kd = require 'kd'
KDCustomScrollViewWrapper = kd.CustomScrollViewWrapper
module.exports = class TerminalWrapper extends KDCustomScrollViewWrapper

  _scrollHorizontally: -> @setScrollLeft 0

  _scrollVertically: do ->

    lastPosition = 0

    ({ speed, velocity }) ->

      return  unless @parent?.terminal

      scrollStep   = @parent.terminal._mbHeight
      isAddition   = velocity > 0
      stepInPixels = if isAddition then scrollStep else -scrollStep
      actPosition  = @getScrollTop()
      remainder    = actPosition % scrollStep
      newPosition  = actPosition + stepInPixels - remainder
      shouldStop   = if isAddition
      then lastPosition > newPosition
      else lastPosition < newPosition

      @setScrollTop lastPosition = newPosition

      return shouldStop
