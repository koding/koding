class CollaborativeDrawingPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @pointRef    = @workspaceRef.child "point"
    @linesRef    = @workspaceRef.child "lines"
    @stateRef    = @workspaceRef.child "state"

    @canvas      = new KDCustomHTMLView
      tagName    : "canvas"
      domId      : "paintCanvas"
      bind       : "mousemove mousedown mouseup"
      attributes :
        width    : 640
        height   : 480
        style    : "border: 2px solid #333;"

    @context     = @canvas.getElement().getContext "2d"
    @drawedQueue = []

    @canvas.on "mousedown", (e) =>
      KD.utils.stopDOMEvent e
      x             = e.offsetX
      y             = e.offsetY
      @startDrawing = yes

      @context.beginPath()
      @context.moveTo e.offsetX, e.offsetY

      @addPoint x, y
      @drawedQueue.push "#{x},#{y}"
      @pointRef.set { x, y }
      @stateRef.set yes

    @canvas.on "mouseup", (e) =>
      @context.closePath()
      @startDrawing = no
      @stateRef.set   no

      @linesRef.push @drawedQueue.join "|"
      @drawedQueue.length = 0

    @canvas.on "mousemove", (e) =>
      if @startDrawing
        x = e.offsetX
        y = e.offsetY

        @addPoint   x, y
        @drawedQueue.push "#{x},#{y}"
        @pointRef.set { x, y }

    @container.addSubView @canvas

    @workspaceRef.onDisconnect().remove()  if @amIHost

    if @isJoinedASession
      @linesRef.once "value", (snapshot) =>
        value = snapshot.val()
        return unless value
        @context.beginPath()
        for key, points of value
          pointsArr = points.split "|"
          for point, index in pointsArr
            [x, y] = point.split ","
            @context.moveTo x, y  if index is 0
            @addPoint x, y

    @isContextMoved = yes

    @pointRef.on "value", (snapshot) =>
      return if @startDrawing
      value = snapshot.val()
      if value
        unless @isContextMoved
          @context.beginPath()
          @context.moveTo value.x, value.y
          @isContextMoved = yes

        @addPoint value.x, value.y

    @stateRef.on "value", (snapshot) =>
      if snapshot.val() is no
        @isContextMoved  = no

  addPoint: (x, y) ->
    ctx = @context
    ctx.lineTo x, y
    ctx.stroke()