$ = require 'jquery'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDModalView = kd.ModalView
KDOverlayView = kd.OverlayView
KDView = kd.View
module.exports = class AnimatedModalView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'animated-modalview', options.cssClass
    super options, data

    @addSubView new KDCustomHTMLView
      partial : \
        "<span class='close-icon closeModal' title='Close [ESC]'></span>"
      click   : @bound 'destroy'

    @putOverlay()  if options.overlay

    @setMagic 0
    @appendToDomBody()

  keyUp: (event) ->
    @destroy() if event.which is 27
    event

  putOverlay: ->
    removable = @getOption 'overlayClick'
    @overlay  = new KDOverlayView
      isRemovable : removable

    if removable
      @overlay.on 'OverlayWillBeRemoved', @bound 'destroy'
      $('body').addClass 'noscroll'

  viewAppended: ->

    @listenWindowResize()
    @setMagic 1

    kd.utils.defer @bound 'setKeyView'

  setMagic: (scale = 1) ->

    _wind  = $(global)
    height = _wind.height()
    width  = _wind.width()

    { x, y, w, h } = @getDelegate().getBounds?() or { x:1, y:1, w:1, h:1 }
    css    = {}

    props  = ['webkitTransform', 'MozTransform', 'transform']
    for prop in props
      css[prop] = """
        scale(#{scale})
        translate(#{Math.floor(width / 2  - 320)}px,
                  #{Math.floor(y + (height / 2 - 240))}px)
      """
    props = ['webkitTransformOrigin', 'MozTransformOrigin', 'transformOrigin']
    css[prop] = "#{x + w / 3}px #{y + h / 3}px"  for prop in props

    @setStyle css

  _windowDidResize: ->

    @setClass 'inresize'
    @setMagic()
    kd.utils.wait 400, => @unsetClass 'inresize'

  destroy: ->

    $('body').removeClass 'noscroll'

    @setMagic 0
    kd.utils.wait 500, =>
      @overlay.destroy()
      KDModalView::destroy.call this
