class CollaborativeDrawingPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @pointRef    = @workspaceRef.child "point"
    @linesRef    = @workspaceRef.child "lines"
    @stateRef    = @workspaceRef.child "state"
    @usersRef    = @workspaceRef.child "users"

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
    @userColors  = {}
    @setUserColor()

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

    @canvas.on "mouseup", (e) =>
      @context.closePath()
      @startDrawing = no
      @stateRef.set   no

      @drawedQueue.unshift KD.nick(), @userColors[KD.nick()]
      @linesRef.push @drawedQueue.join "|"
      @drawedQueue.length = 0

    @canvas.on "mousemove", (e) =>
      if @startDrawing
        x = e.offsetX
        y = e.offsetY

        @addPoint x, y
        @drawedQueue.push "#{x},#{y}"

        @pointRef.set { x, y, nickname: KD.nick() }

    @container.addSubView @canvas

    @workspaceRef.onDisconnect().remove()  if @amIHost

    if @isJoinedASession
      @context.closePath()
      @linesRef.once "value", (snapshot) =>
        value = snapshot.val()
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

    @isContextMoved = yes

    @pointRef.on "value", (snapshot) =>
      return if @startDrawing
      value = snapshot.val()
      if value
        unless @isContextMoved
          @context.beginPath()
          @context.moveTo value.x, value.y
          @isContextMoved = yes

        @addPoint value.x, value.y, value.nickname

    @stateRef.on "value", (snapshot) =>
      @isContextMoved = snapshot.val() isnt no

    @usersRef.on "value", (snapshot) =>
      value = snapshot.val()
      return unless value
      for own key, userData of value
        @userColors[userData.nickname] = userData.color


  addPoint: (x, y, nickname = KD.nick()) ->
    ctx             = @context
    ctx.strokeStyle = @userColors[nickname]
    ctx.lineTo x, y
    ctx.stroke()

  setUserColor: () ->
    nickname              = KD.nick()
    color                 = KD.utils.getRandomHex()
    @userColors[nickname] = color
    @usersRef.push { nickname, color }
