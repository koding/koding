_ = require 'lodash'
$ = require 'jquery'

kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDObject = kd.Object
Cursor = require './cursor'
InputHandler = require './inputhandler'
ScreenBuffer = require './screenbuffer'
Style      = require './style'
StyledText = require './styledtext'
createANSIControlCodeReader = require './createansicontrolcodereader'


module.exports = class Terminal extends KDObject

  LINE_DRAWING_CHARSET = [
    0x2191, 0x2193, 0x2192, 0x2190, 0x2588, 0x259a, 0x2603
    null, null, null, null, null, null, null, null, null, null, null, null
    null, null, null, null, null, null, null, null, null, null, null
    0x0020, 0x25c6, 0x2592, 0x2409, 0x240c, 0x240d, 0x240a, 0x00b0
    0x00b1, 0x2424, 0x240b, 0x2518, 0x2510, 0x250c, 0x2514, 0x253c
    0x23ba, 0x23bb, 0x2500, 0x23bc, 0x23bd, 0x251c, 0x2524, 0x2534
    0x252c, 0x2502, 0x2264, 0x2265, 0x03c0, 0x2260, 0x00a3, 0x00b7
  ]

  SPECIAL_CHARS =
    '\b'     : '\\b'
    '\t'     : '\\t'
    '\n'     : '\\n'
    '\f'     : '\\f'
    '\r'     : '\\r'
    '\\'     : '\\\\'
    '\u001b' : '\\e'


  constructor: (options) ->

    { containerView, @readOnly } = options

    super options

    if @readOnly
      for keyHandler in ['keyDown', 'keyPress', 'keyUp', 'paste']
        @[keyHandler] = kd.noop

    @parent               = containerView
    @container            = containerView.$()
    @server               = null
    @sessionEndedCallback = null
    @setTitleCallback     = null

    @keyInput = new KDCustomHTMLView
      tagName   : 'input'
      attributes: { type: 'text' }
      cssClass  : 'offscreen'
      bind      : 'keydown keyup keypress paste'
      keydown   : @bound 'keyDown'
      keypress  : @bound 'keyPress'
      keyup     : @bound 'keyUp'
    @keyInput.appendToDomBody()
    @keyInput.on 'paste', @bound 'paste'

    containerView.on 'KDObjectWillBeDestroyed', @keyInput.bound 'destroy'

    @currentWidth             = 0
    @currentHeight            = 0
    @sizeX                    = 80
    @sizeY                    = 24
    @currentStyle             = StyledText.DEFAULT_STYLE
    @currentWhitespaceStyle   = null
    @currentCharacterSets     = ['B', 'A', 'A', 'A']
    @currentCharacterSetIndex = 0

    @inputHandler      = new InputHandler(this)
    @screenBuffer      = new ScreenBuffer(this)
    @cursor            = new Cursor(this)
    @cursor.stopBlink()  if @readOnly

    @controlCodeReader = createANSIControlCodeReader(this)

    @measurebox = new KDCustomHTMLView
      partial   : '\xA0'
      cssClass  : 'offscreen'

    outputboxElement = global.document.createElement 'div'
    @outputbox = $ outputboxElement
    @outputbox.attr 'contenteditable', not @readOnly
    @outputbox.attr 'spellcheck', off
    @outputbox.css 'cursor', 'text'
    @outputbox.append @measurebox.getDomElement()

    @container.append @outputbox

    outputboxElement.addEventListener 'keydown', do =>
      controlMeta = no
      (event) =>
        range = kd.utils.getSelectionRange()
        return  if range.startOffset is range.endOffset
        if event.ctrlKey or event.metaKey
          return  controlMeta = yes  if event.keyIdentifier in ['Control', 'Meta']
          char = String.fromCharCode event.which
          if char is 'X' then return @setKeyFocus()
          else if char in ['C', 'V'] then return
          else if controlMeta then @setKeyFocus()
          controlMeta = no
        else
          @setKeyFocus()

    outputboxElement.addEventListener 'keypress', (event) =>
      kd.utils.stopDOMEvent event  if event.target isnt @keyInput.getElement()
    , yes

    @outputbox.on 'keydown', (event) =>
      if @mousedownHappened
        @setKeyFocus() unless event.ctrlKey or event.metaKey
        kd.utils.defer =>
          @mousedownHappened = false

    @outputbox.on 'paste', @bound 'paste'

    @outputbox.on 'drop', (event) =>
      @server.input event.originalEvent.dataTransfer.getData 'text/plain'
      kd.utils.stopDOMEvent event

    @updateSize()

    @container.on 'mousedown mousemove mouseup wheel contextmenu', (event) =>
      @inputHandler.mouseEvent event

    @clientInterface =
      output: (data) =>
        kd.log @inspectString(data) if localStorage?['WebTerm.logRawOutput'] is 'true'
        @controlCodeReader.addData data
        if localStorage?['WebTerm.slowDrawing'] is 'true'
          @controlCodeInterval ?= global.setInterval =>
            atEnd = @controlCodeReader.process()
            if localStorage?['WebTerm.slowDrawing'] isnt 'true'
              atEnd = @controlCodeReader.process() until atEnd
            @screenBuffer.flush()
            if atEnd
              global.clearInterval @controlCodeInterval
              @controlCodeInterval = null
          , 20
        else
          atEnd = false
          atEnd = @controlCodeReader.process() until atEnd
          @screenBuffer.flush()

      sessionEnded: =>
        @sessionEndedCallback()

  command: (command) -> @emit 'command', command

  destroy: ->
    @keyInput?.destroy()
    super()

  ignoreKeyDownEvent = (event) ->
    (event.ctrlKey or event.metaKey) and event.shiftKey and event.keyCode is 13

  keyDown: (event) ->
    return  if @isReadOnly
    return  if ignoreKeyDownEvent event

    @inputHandler.keyDown event

  keyPress: (event) ->
    return  if @isReadOnly

    @inputHandler.keyPress event

  keyUp: (event) ->
    return  if @isReadOnly

    @inputHandler.keyUp event

  setKeyFocus: ->
    @keyInput.getElement().focus()

  setFocused: (value) ->
    @cursor.setFocused value
    if value then kd.utils.defer => @setKeyFocus()

  setSize: (x, y, emit = yes) ->

    return  if x is @sizeX and y is @sizeY

    cursorLineIndex  = @screenBuffer.toLineIndex(@cursor.y)
    [@sizeX, @sizeY] = [x, y]
    @screenBuffer.scrollingRegion = [0, y - 1]

    @cursor.moveTo @cursor.x, cursorLineIndex - @screenBuffer.toLineIndex(0)
    if @server
      @emit 'ScreenSizeChanged', { w: x, h: y }  if emit
      @server.setSize x, y

  getCharSizes: ->
    sizes =
      width  : @measurebox.getWidth()  or @_mbWidth  or 7
      height : @measurebox.getHeight() or @_mbHeight or 14

    [@_mbWidth, @_mbHeight] = [@measurebox.getWidth(), @measurebox.getHeight()]

    return sizes


  updateSize: (force = no) ->

    return  unless @parent

    @updateAppSize()

    [swidth, sheight] = [@parent.getWidth(), @parent.getHeight()]

    return  if 0 in [swidth, sheight]
    return  if not force and swidth is @currentWidth and sheight is @currentHeight

    @scrollToBottom()

    [@currentWidth, @currentHeight] = [swidth, sheight]
    { width: charWidth, height: charHeight } = @getCharSizes()

    newCols = Math.max 1, Math.floor swidth  / charWidth
    newRows = Math.max 1, Math.floor sheight / charHeight

    @setSize newCols, newRows


  updateAppSize: ->

    { appView } = @getOptions()
    { width: charWidth, height: charHeight } = @getCharSizes()

    return  unless appView.parent

    height = appView.parent.getHeight() - 24 # padding

    newHeight = Math.floor(height / charHeight) * charHeight

    appView.setHeight newHeight


  windowDidResize: _.debounce (-> @updateSize()), 100

  lineFeed: ->
    if @cursor.y is @screenBuffer.scrollingRegion[1]
      @screenBuffer.scroll 1
    else
      @cursor.move 0, 1

  reverseLineFeed: ->
    if @cursor.y is @screenBuffer.scrollingRegion[0]
      @screenBuffer.scroll -1
    else
      @cursor.move(0, -1)

  writeText: (text, options) ->
    return if text.length is 0
    x = options?.x ? @cursor.x
    y = options?.y ? @cursor.y
    style = options?.style ? @currentStyle
    insert = options?.insert ? false

    lineIndex = @screenBuffer.toLineIndex y
    oldContent = @screenBuffer.getLineContent lineIndex
    newContent = oldContent.substring 0, x

    text = text.replace /[ ]/g, '\xA0' # NBSP
    switch @currentCharacterSets[@currentCharacterSetIndex]
      when '0'
        nonBoldStyle = new Style style
        nonBoldStyle.bold = false
        for i in [0..text.length]
          c = text.charCodeAt i
          u = LINE_DRAWING_CHARSET[c - 0x41] ? c
          charStyle = if u >= 0x2300 then nonBoldStyle else style
          newContent.push new StyledText(String.fromCharCode(u), charStyle)
      when 'A'
        text = text.replace /#/g, '\xA3' # pound sign
        newContent.push new StyledText(text, style)
      else
        newContent.push new StyledText(text, style)

    newContent.pushAll oldContent.substring(if insert then x else x + text.length)
    @screenBuffer.setLineContent lineIndex, newContent

  writeEmptyText: (length, options) ->
    if not @currentWhitespaceStyle?
      @currentWhitespaceStyle = new Style @currentStyle
      @currentWhitespaceStyle.inverse = false
    @currentWhitespaceStyle
    options ?= {}
    options.style = @currentWhitespaceStyle
    text = ''
    text += '\xA0' for i in [0...length]
    @writeText text, options

  deleteCharacters: (count, options) ->
    x = options?.x ? @cursor.x
    y = options?.y ? @cursor.y
    lineIndex = @screenBuffer.toLineIndex y
    oldContent = @screenBuffer.getLineContent lineIndex
    newContent = oldContent.substring 0, x
    newContent.pushAll oldContent.substring(x + count)
    text = ''
    text += '\xA0' for i in [0...count]
    if lastLine = oldContent.get oldContent.length() - 1
      newContent.push new StyledText(text, lastLine.style)
    @screenBuffer.setLineContent lineIndex, newContent

  setStyle: (name, value) ->
    @currentStyle = new Style @currentStyle
    @currentStyle[name] = value
    @currentWhitespaceStyle = null

  resetStyle: ->
    @currentStyle = StyledText.DEFAULT_STYLE
    @currentWhitespaceStyle = null

  setCharacterSet: (index, charset) ->
    @currentCharacterSets[index] = charset

  setCharacterSetIndex: (index) ->
    @currentCharacterSetIndex = index

  changeScreenBuffer: (index) ->

  isScrolledToBottom: -> @parent.isAtBottom()

  scrollToBottom: (animate = no) ->

    return  if @isScrolledToBottom()

    @container.stop()

    if animate
    then @container.animate { scrollTop : @parent.getScrollHeight() - @parent.getHeight() }, { duration : 200 }
    else @parent.scrollToBottom()


  setScrollbackLimit: (limit) ->
    @screenBuffer.scrollbackLimit = limit
    @screenBuffer.flush()


  inspectString: (string) ->
    escaped = string.replace /[\x00-\x1f\\]/g, (character) ->
      special = SPECIAL_CHARS[character]
      return special if special
      hex = character.charCodeAt(0).toString(16).toUpperCase()
      hex = '0' + hex if hex.length is 1
      '\\x' + hex
    '"' + escaped.replace('"', '\\"') + '"'


  paste: (event) =>

    return  if @isReadOnly

    kd.utils.stopDOMEvent event
    @server.input event.originalEvent.clipboardData.getData 'text/plain'
    @setKeyFocus()
