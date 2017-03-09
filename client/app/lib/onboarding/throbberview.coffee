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
    @listenWindowResize()


  appendToParent: ->

    { targetIsScrollable } = @getOptions()
    targetElement          = @getDelegate()

    if targetIsScrollable
      targetElement.append @getDomElement()
      targetElement.css 'position', 'relative'  if targetElement.css('position') is 'static'
    else
      @appendToDomBody()


  createThrobberElement: ->

    @addSubView new KDView
      tagName   : 'figure'
      cssClass  : 'throbber'
      partial   : '<i></i><i></i>'


  showTooltip: ->

    { placementX, placementY, tooltipText, tooltipPlacement, targetIsScrollable } = @getOptions()

    if tooltipPlacement is 'auto' or not tooltipPlacement
      tooltipPlacement = if placementX is 'left' then 'left' else 'right'

    tooltipView = new KDCustomHTMLView
      cssClass : 'throbber-tooltip-text'
      partial  : tooltipText

    helper.setupLinksTarget tooltipView

    tooltipView.addSubView new KDCustomHTMLView
      tagName  : 'a'
      cssClass : 'close-icon'
      click    : @bound 'closeTooltip'

    @setTooltip
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

    super

    return  unless @scrollWrapper

    @scrollWrapper.off 'scroll', @bound 'unsetTooltip'
    @scrollWrapper.verticalThumb.off 'DragInAction', @bound 'unsetTooltip'
    @scrollWrapper = null


  closeTooltip: ->

    @unsetTooltip()
    @emit 'TooltipClosed'


  setPosition: ->

    { placementX, placementY, offsetX, offsetY, targetIsScrollable } = @getOptions()

    targetElement       = @getDelegate()
    targetClientRect    = targetElement[0].getBoundingClientRect()
    targetElementX      = if targetIsScrollable then 0 else targetClientRect.left
    targetElementY      = if targetIsScrollable then 0 else targetClientRect.top
    targetElementWidth  = targetElement.outerWidth()
    targetElementHeight = targetElement.outerHeight()

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

    @tooltip?.setPositions()


  click: (event) ->

    kd.utils.stopDOMEvent event
    if @tooltip then @closeTooltip() else @showTooltip()


  show: ->

    super

    @showTooltip()  if @tooltip


  hide: ->

    super

    @tooltip?.hide()


  listenToScrollEvent: ->

    @scrollWrapper = helper.findScrollWrapper this
    return  unless @scrollWrapper

    @scrollWrapper.on 'scroll', @bound 'unsetTooltip'
    @scrollWrapper.verticalThumb.on 'DragInAction', @bound 'unsetTooltip'


  destroy: ->

    @unsetTooltip()
    super


  _windowDidResize: ->

    @setPosition()  unless @hasClass 'hidden'


  ###
   HELPER METHODS
  ###
  helper =

    setupLinksTarget: (tooltipView) ->

      links = tooltipView.getElement().querySelectorAll 'a'
      for link in links
        link.setAttribute 'target', '_blank'  unless link.getAttribute 'target'


    findScrollWrapper: (view) ->

      { parent } = view

      return  unless parent

      return parent  if parent instanceof KDCustomScrollViewWrapper
      return helper.findScrollWrapper parent
