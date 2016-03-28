kd         = require 'kd'
Style      = require './style'
StyledText = require './styledtext'


module.exports = class Cursor

  constructor: (terminal) ->

    @terminal      = terminal
    @element       = null

    @x             = 0
    @y             = 0
    @savedX        = 0
    @savedY        = 0

    @inversed      = yes
    @visible       = yes
    @focused       = yes

    @blinkInterval = null
    @windowFocused = yes

    kd.singletons.windowController.addFocusListener (state) =>
      @windowFocused = state
      @resetBlink()

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

    return  if @visible is value

    @visible = value
    @element = null

    @terminal.screenBuffer.addLineToUpdate @y


  setFocused: (value) ->
    return  if @focused is value or @stopped

    @focused = value
    @resetBlink()


  setBlinking: (blinking) ->
    @blinking = blinking
    @resetBlink()


  stopBlink: ->
    @stopped = true
    @resetBlink()


  resetBlink: ->

    if @blinkInterval?
      global.clearInterval @blinkInterval
      @blinkInterval = null

    @inversed = yes
    @updateCursorElement()

    slowDrawing = localStorage?['WebTerm.slowDrawing'] is 'true'

    if @blinking and (@focused and @windowFocused and not @stopped)
      @blinkInterval = global.setInterval =>
        @inversed = slowDrawing or not @inversed
        @updateCursorElement()
      , 600


  addCursorElement: (content) ->

    return content  unless @visible

    newContent = content.substring 0, @x
    newContent.merge = no

    if @element = content.substring(@x, @x + 1).get 0
      @element.style = new Style @element.style
    else
      @element = new StyledText ' ', @terminal.currentStyle

    @element.spanForced     = yes
    @element.style.outlined = not @focused
    @element.style.inverse  =  @focused and @inversed

    newContent.push @element
    newContent.pushAll content.substring @x + 1

    return newContent


  updateCursorElement: ->

    return  unless @element?

    @element.style.outlined = not @focused
    @element.style.inverse  =  @focused and @inversed

    @element.updateNode()
