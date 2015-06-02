kd = require 'kd'
KDView = kd.View

module.exports = class ThrobberView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass     = kd.utils.curry 'throbber', options.cssClass
    options.placementX or= 'top'
    options.placementY or= 'left'
    options.offsetX    or= 0
    options.offsetY    or= 0

    super options, data

    @appendToDomBody()
    @createElements()
    @setPosition()


  createElements: ->

    { placementX, placementY, tooltipText, tooltipPlacement } = @getOptions()

    @addSubView new KDView { cssClass: 'throbber-outer-circle' }
    @addSubView new KDView { cssClass: 'throbber-inner-circle' }

    if tooltipPlacement is 'auto' or not tooltipPlacement
      tooltipPlacement = if placementX is 'left' then 'left' else 'right'

    @setTooltip
      title     : "<div class='throbber-tooltip-text'>#{tooltipText}<div>"
      cssClass  : 'throbber-tooltip'
      placement : tooltipPlacement
      html      : yes
      sticky    : yes


  setPosition: ->

    { placementX, placementY, offsetX, offsetY } = @getOptions()

    targetElement       = @getDelegate()
    targetElementX      = targetElement.getX()
    targetElementY      = targetElement.getY()
    targetElementWidth  = targetElement.getWidth()
    targetElementHeight = targetElement.getHeight()

    throbberWidth       = @getWidth()
    throbberHeight      = @getHeight()

    throbberX = switch placementX
      when 'right'  then targetElementX + targetElementWidth - throbberWidth
      when 'center' then targetElementX + (targetElementWidth - throbberWidth) / 2
      else targetElementX
    throbberX += offsetX

    throbberY = switch placementY
      when 'bottom' then targetElementY + targetElementHeight - throbberHeight
      when 'center' then targetElementY + (targetElementHeight - throbberHeight) / 2
      else targetElementY
    throbberY += offsetY

    @getDomElement().css
      left : throbberX
      top  : throbberY
