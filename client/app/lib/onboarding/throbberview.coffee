kd = require 'kd'
KDView = kd.View
KDCustomHTMLView = kd.CustomHTMLView
KDCustomScrollViewWrapper = kd.CustomScrollViewWrapper

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


  setTooltip: ->

    { placementX, placementY, tooltipText, tooltipPlacement, targetIsScrollable } = @getOptions()

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
      click    : @bound 'closeTooltip'

    super
      view      : tooltipView
      cssClass  : 'throbber-tooltip just-text'
      placement : tooltipPlacement
      html      : yes
      sticky    : yes
      permanent : yes

    @tooltip.show()
    @listenToScrollEvent()  if targetIsScrollable

    @emit 'TooltipShown'


  unsetTooltip: ->

    return  unless @tooltip

    @scrollWrapper?.off 'scroll', @bound 'unsetTooltip'
    @scrollWrapper?.verticalThumb.off 'DragInAction', @bound 'unsetTooltip'
    @scrollWrapper = null

    super


  closeTooltip: ->

    @unsetTooltip()
    @emit 'TooltipClosed'


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


  click: (event) ->

    if @tooltip?
      @closeTooltip()
    else
      @setTooltip()


  show: ->

    super
    #reinit tooltip if it was hidden before
    @setTooltip()  if @tooltip?


  hide: ->

    super
    @tooltip?.hide()


  listenToScrollEvent: ->

    @scrollWrapper = @findScrollWrapper this
    return  unless @scrollWrapper

    @scrollWrapper.on 'scroll', @bound 'unsetTooltip'
    @scrollWrapper.verticalThumb.on 'DragInAction', @bound 'unsetTooltip'


  findScrollWrapper: (view) ->

    { parent } = view

    return  unless parent

    return parent  if parent instanceof KDCustomScrollViewWrapper
    return @findScrollWrapper parent


  destroy: ->

    @unsetTooltip()
    super
