kd = require 'kd'
raf = require 'raf'

module.exports = class NoiseView extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'NoiseView'
    options.lazyAnimate ?= no
    options.size or= { width: 10, height: 10 }

    super options, data

    { width, height } = @options.size

    @addSubView @_canvas = new kd.CustomHTMLView
      tagName    : 'canvas'
      attributes : { width, height }

    @startNoiseAnimation()  unless @options.lazyAnimate


  changeNoisyFrame: ->

    context = @_canvas.getElement().getContext '2d'

    @_canvas.getElement().width  = @options.size.width
    @_canvas.getElement().height = @options.size.height

    { width, height } = context.canvas
    imageData         = context.createImageData width, height

    buffer = new Uint32Array imageData.data.buffer

    for _, i in buffer
      buffer[i] = ((255 * Math.random()) | 0) << 24

    context.putImageData imageData, 0, 0


  startNoiseAnimation: ->

    STOP = no
    RUN  = yes

    FRAMES = [STOP, STOP, RUN, STOP, STOP, STOP]

    count = 0

    frameFn = =>
      return  if @destroyed

      # don't change frame if it has STOP
      return @_rafId = raf frameFn  unless FRAMES[(count++) % FRAMES.length]

      @changeNoisyFrame()
      @_rafId = raf frameFn

    @_rafId = raf frameFn


  stopNoiseAnimation: ->

    raf.cancel @_rafId


  show: ->

    super

    @stopNoiseAnimation()
    @startNoiseAnimation()


  destroy: ->

    @stopNoiseAnimation()

    super


