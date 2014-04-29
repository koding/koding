class CollaborativeDrawingPane extends CollaborativePane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "ws-drawing-pane", options.cssClass

    super options, data

    @pointRef    = @workspaceRef.child "point"
    @linesRef    = @workspaceRef.child "lines"
    @stateRef    = @workspaceRef.child "state"
    @usersRef    = @workspaceRef.child "users"
    @drawedQueue = []
    @userColors  = {}

    @container.on "viewAppended", =>
      @createCanvas()
      @setUserColor()

      @bindMouseDownOnCanvas()
      @bindMouseUpOnCanvas()
      @bindMouseMoveCanvas()

      @redrawCanvas()  if @isJoinedASession

      @bindRemoteEvents()
      @container.addSubView @canvas

  createCanvas: ->
    @canvas      = new KDCustomHTMLView
      tagName    : "canvas"
      bind       : "mousemove mousedown mouseup"
      attributes :
        width    : @getWidth()
        height   : @getHeight()

    @context     = @canvas.getElement().getContext "2d"

  redrawCanvas: ->
    @context.closePath()
    @linesRef.once "value", (snapshot) =>
      value = @workspace.reviveSnapshot snapshot
      return unless value
      @context.beginPath()
      for own key, points of value
        pointsArr = points.split "|"
        [username, color]     = pointsArr.splice 0, 2
        @userColors[username] = color

        @context.closePath()
        @context.beginPath()
        for point, index in pointsArr
          [x, y] = point.split ","
          @context.moveTo x, y  if index is 0
          @addPoint x, y, username

  bindMouseDownOnCanvas: ->
    @canvas.on "mousedown", (e) =>
      KD.utils.stopDOMEvent e
      x             = e.offsetX
      y             = e.offsetY
      @startDrawing = yes

      @context.beginPath()
      @context.moveTo e.offsetX, e.offsetY

      @addPoint x, y
      @drawedQueue.push "#{x},#{y}"
      @pointRef.set { x, y, nickname: KD.nick() }
      @stateRef.set yes

  bindMouseMoveCanvas: ->
    @canvas.on "mousemove", (e) =>
      if @startDrawing
        x = e.offsetX
        y = e.offsetY

        @addPoint x, y
        @drawedQueue.push "#{x},#{y}"

        @pointRef.set { x, y, nickname: KD.nick() }

  bindMouseUpOnCanvas: ->
    @canvas.on "mouseup", (e) =>
      @context.closePath()
      @startDrawing = no
      @stateRef.set   no

      @drawedQueue.unshift KD.nick(), @userColors[KD.nick()]
      @linesRef.push @drawedQueue.join "|"
      @drawedQueue.length = 0

  bindRemoteEvents: ->
    @isContextMoved = yes

    @pointRef.on "value", (snapshot) =>
      return if @startDrawing
      value = @workspace.reviveSnapshot snapshot
      if value
        unless @isContextMoved
          @context.beginPath()
          @context.moveTo value.x, value.y
          @isContextMoved = yes

        @addPoint value.x, value.y, value.nickname

    @stateRef.on "value", (snapshot) =>
      @isContextMoved = @workspace.reviveSnapshot(snapshot) isnt no

    @usersRef.on "value", (snapshot) =>
      value = @workspace.reviveSnapshot snapshot
      return unless value
      for own key, userData of value
        @userColors[userData.nickname] = userData.color

  addPoint: (x, y, nickname = KD.nick()) ->
    ctx             = @context
    ctx.strokeStyle = @userColors[nickname]
    ctx.lineTo x, y
    ctx.stroke()

  setUserColor: ->
    nickname              = KD.nick()
    color                 = KD.utils.getRandomHex()
    @userColors[nickname] = color
    @usersRef.push { nickname, color }
