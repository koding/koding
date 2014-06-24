class WebTerm.Cursor
  constructor: (@terminal) ->
    @x = 0
    @y = 0
    @element = null
    @inversed = true
    @visible = true
    @focused = true
    @blinkInterval = null
    @savedX = 0
    @savedY = 0
    @resetBlink()

  move: (x, y) ->
    @moveTo @x + x, @y + y

  moveTo: (x, y) ->
    x = Math.max x, 0
    y = Math.max y, 0
    x = Math.min x, @terminal.sizeX - 1
    y = Math.min y, @terminal.sizeY - 1
    return if x is @x and y is @y

    @x = x
    lastY = @y
    @y = y
    @terminal.screenBuffer.addLineToUpdate lastY if lastY < @terminal.sizeY and y isnt lastY
    @terminal.screenBuffer.addLineToUpdate y

  savePosition: ->
    @savedX = @x
    @savedY = @y

  restorePosition: ->
    @moveTo @savedX, @savedY

  setVisibility: (value) ->
    return if @visible is value
    @visible = value
    @element = null
    @terminal.screenBuffer.addLineToUpdate @y

  setFocused: (value) ->
    return if @focused is value or @stopped
    @focused = value
    @resetBlink()

  stopBlink: ->
    @stopped = true
    @resetBlink()

  resetBlink: ->
    if @blinkInterval?
      window.clearInterval @blinkInterval
      @blinkInterval = null
    @inversed = true
    @updateCursorElement()
    if @focused and not @stopped
      @blinkInterval = window.setInterval =>
        @inversed = if localStorage?["WebTerm.slowDrawing"] is "true" then true else not @inversed
        @updateCursorElement()
      , 600

  addCursorElement: (content) ->
    return content if not @visible
    newContent = content.substring 0, @x
    newContent.merge = false
    @element = content.substring(@x, @x + 1).get(0) ? new WebTerm.StyledText(" ", @terminal.currentStyle)
    @element.spanForced = true
    @element.style = jQuery.extend true, {}, @element.style
    @element.style.outlined = not @focused
    @element.style.inverse = @focused and @inversed
    newContent.push @element
    newContent.pushAll content.substring(@x + 1)
    newContent

  updateCursorElement: ->
    return if not @element?
    @element.style.outlined = not @focused
    @element.style.inverse = @focused and @inversed
    @element.updateNode()
