kd = require 'kd'
KDContextMenu = kd.ContextMenu
module.exports = class OnboardingContextMenu extends KDContextMenu

  viewAppended: ->

    kd.utils.wait 50, =>
      shiftX     = 20
      shiftY     = 40
      arrowWidth = 10

      menuWidth  = @getWidth()
      menuHeight = @getHeight()

      mainView   = kd.getSingleton 'mainView'

      mainWidth  = mainView.getWidth()
      mainHeight = mainView.getHeight()

      element    = @getDelegate()
      elementX   = element.getX()
      elementY   = element.getY()

      elementWidth  = element.getWidth()
      elementHeight = element.getHeight()

      arrow =
        placement : 'top'

      menuX = elementX - shiftX
      if menuX + menuWidth > mainWidth
        menuX = mainWidth - menuWidth

      arrow.margin = elementX - menuX + Math.min(elementWidth, elementHeight) / 2 - arrowWidth / 2

      menuY = elementY + shiftY
      if menuY + menuHeight > mainHeight
        menuY = elementY - menuHeight - shiftY
        arrow.placement = 'bottom'

      @setOption 'x',     menuX
      @setOption 'y',     menuY
      @setOption 'arrow', arrow

      @positionContextMenu()
      @addArrow()

      kd.utils.wait 20, =>
        @getDomElement().css 'visibility', 'visible'

