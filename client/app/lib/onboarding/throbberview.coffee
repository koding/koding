kd = require 'kd'
KDView = kd.View
KDCustomHTMLView = kd.CustomHTMLView

module.exports = class ThrobberView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass     = kd.utils.curry 'throbber', options.cssClass
    options.placementX or= 'top'
    options.placementY or= 'left'
    options.offsetX     ?= 0
    options.offsetY     ?= 0

    super options, data

    @appendToParent()
    @createThrobberElement()
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


  createThrobberElement: ->

    @addSubView new KDView
      tagName   : 'figure'
      cssClass  : 'throbber'
      partial   : '<i></i><i></i>'


  createTooltip: ->

    { placementX, placementY, tooltipText, tooltipPlacement } = @getOptions()

    if tooltipPlacement is 'auto' or not tooltipPlacement
      tooltipPlacement = if placementX is 'left' then 'left' else 'right'

    tooltipView = new KDCustomHTMLView
      cssClass : 'throbber-tooltip-text'
      partial  : tooltipText

    # open links inside of tooltip in a new tab
    links = tooltipView.getElement().querySelectorAll 'a'
    link.setAttribute 'target', '_blank' for link in links

    tooltipView.addSubView new KDCustomHTMLView
      tagName  : 'a'
      cssClass : 'close-icon'
      click    : @bound 'destroyTooltip'

    @setTooltip
      view      : tooltipView
      cssClass  : 'throbber-tooltip just-text'
      placement : tooltipPlacement
      html      : yes
      sticky    : yes
      permanent : yes

    @tooltip.show()


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


  click: ->

    if @tooltip?
      @destroyTooltip()
    else
      @createTooltip()
      @emit 'TooltipCreated'


  destroyTooltip: ->

    return  unless @tooltip

    @unsetTooltip()
    @emit 'TooltipDestroyed'


  show: ->

    super
    @tooltip?.show()


  hide: ->

    super
    @tooltip?.hide()