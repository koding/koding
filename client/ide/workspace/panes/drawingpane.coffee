class IDE.DrawingPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'drawing-pane', options.cssClass
    options.paneType = 'drawing'

    super options, data

  viewAppended: ->
    super

    @createCanvas()
    @setColor()

    @bindMouseDownOnCanvas()
    @bindMouseUpOnCanvas()
    @bindMouseMoveCanvas()

    @addSubView @canvas

  createCanvas: ->
    @canvas      = new KDCustomHTMLView
      tagName    : 'canvas'
      bind       : 'mousemove mousedown mouseup'
      attributes :
        width    : @getWidth()
        height   : @getHeight()

    @context     = @canvas.getElement().getContext '2d'

  bindMouseDownOnCanvas: ->
    @canvas.on 'mousedown', (e) =>
      KD.utils.stopDOMEvent e
      x             = e.offsetX
      y             = e.offsetY
      @startDrawing = yes

      @context.beginPath()
      @context.moveTo e.offsetX, e.offsetY

      @addPoint x, y

  bindMouseMoveCanvas: ->
    @canvas.on 'mousemove', (e) =>
      if @startDrawing
        x = e.offsetX
        y = e.offsetY

        @addPoint x, y

  bindMouseUpOnCanvas: ->
    @canvas.on 'mouseup', (e) =>
      @context.closePath()
      @startDrawing = no

  addPoint: (x, y, nickname = KD.nick()) ->
    ctx             = @context
    ctx.strokeStyle = @color
    ctx.lineTo x, y
    ctx.stroke()

  setColor: ->
    nickname  = KD.nick()
    @color    = KD.utils.getColorFromString nickname
