kd = require 'kd'
KDView = kd.View

module.exports = class ThrobberView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass     = kd.utils.curry 'throbber', options.cssClass
    options.placementX or= 'top'
    options.placementY or= 'left'
    options.offsetX     ?= 0
    options.offsetY     ?= 0

    super options, data

    @appendToParent()
    @createElements()
    @setPosition()


  appendToParent: ->

    { targetIsScrollable } = @getOptions()
    targetElement          = @getDelegate()
    targetDomElement       = targetElement.getDomElement()

    if targetIsScrollable
      targetElement.addSubView this
      targetElement.setCss 'position', 'relative'  if targetDomElement.css('position') is 'static'
    else
      @appendToDomBody()


  createElements: ->

    { placementX, placementY, tooltipText, tooltipPlacement } = @getOptions()

    @addSubView new KDView
      tagName   : 'figure'
      cssClass  : 'throbber'
      partial   : '<i></i><i></i>'

    if tooltipPlacement is 'auto' or not tooltipPlacement
      tooltipPlacement = if placementX is 'left' then 'left' else 'right'

    @setTooltip
      title     : "<div class='throbber-tooltip-text'>#{tooltipText}<div>"
      cssClass  : 'throbber-tooltip'
      placement : tooltipPlacement
      html      : yes


  setPosition: ->

    { placementX, placementY, offsetX, offsetY, targetIsScrollable } = @getOptions()

    targetElement       = @getDelegate()
    targetElementX      = if targetIsScrollable then 0 else targetElement.getX()
    targetElementY      = if targetIsScrollable then 0 else targetElement.getY()
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
