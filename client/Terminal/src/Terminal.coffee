class WebTerm.Terminal extends KDObject
  LINE_DRAWING_CHARSET = [0x2191, 0x2193, 0x2192, 0x2190, 0x2588, 0x259a, 0x2603, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0x0020, 0x25c6, 0x2592, 0x2409, 0x240c, 0x240d, 0x240a, 0x00b0, 0x00b1, 0x2424, 0x240b, 0x2518, 0x2510, 0x250c, 0x2514, 0x253c, 0x23ba, 0x23bb, 0x2500, 0x23bc, 0x23bd, 0x251c, 0x2524, 0x2534, 0x252c, 0x2502, 0x2264, 0x2265, 0x03c0, 0x2260, 0x00a3, 0x00b7]

  SPECIAL_CHARS =
    '\b': '\\b'
    '\t': '\\t'
    '\n': '\\n'
    '\f': '\\f'
    '\r': '\\r'
    '\\': '\\\\'
    '\u001b': '\\e'

  constructor: (options)->

    { containerView, @readOnly } = options

    super()

    if @readOnly
      for keyHandler in ['keyDown', 'keyPress', 'keyUp', 'paste']
        @[keyHandler] = noop

    localStorage?["WebTerm.logRawOutput"] ?= "false"
    localStorage?["WebTerm.slowDrawing"]  ?= "false"

    @parent               = containerView
    @container            = containerView.$()
    @server               = null
    @sessionEndedCallback = null
    @setTitleCallback     = null

    @keyInput = new KDCustomHTMLView
      tagName   : 'input'
      attributes: type: 'text'
      cssClass  : 'offscreen'
      bind      : 'keydown keyup keypress paste'
      keydown   : @bound 'keyDown'
      keypress  : @bound 'keyPress'
      keyup     : @bound 'keyUp'
    @keyInput.appendToDomBody()
    @keyInput.on "paste", @bound "paste"

    containerView.on 'KDObjectWillBeDestroyed', @keyInput.bound 'destroy'

    @currentWidth             = 0
    @currentHeight            = 0
    @sizeX                    = 80
    @sizeY                    = 24
    @currentStyle             = WebTerm.StyledText.DEFAULT_STYLE
    @currentWhitespaceStyle   = null
    @currentCharacterSets     = ["B", "A", "A", "A"]
    @currentCharacterSetIndex = 0

    @inputHandler      = new WebTerm.InputHandler(this)
    @screenBuffer      = new WebTerm.ScreenBuffer(this)
    @cursor            = new WebTerm.Cursor(this)
    @cursor.stopBlink()  if @readOnly

    @controlCodeReader = WebTerm.createAnsiControlCodeReader(this)

    @measurebox = new KDCustomHTMLView
      partial   : "\xA0"
      cssClass  : 'offscreen'

    outputboxElement = document.createElement "div"
    @outputbox = $ outputboxElement
    @outputbox.attr "contenteditable", !@readOnly
    @outputbox.attr "spellcheck", off
    @outputbox.css "cursor", "text"
    @outputbox.append @measurebox.getDomElement()
    @container.append @outputbox

    outputboxElement.addEventListener "keydown", do =>
      controlMeta = no
      (event) =>
        range = KD.utils.getSelectionRange()
        return  if range.startOffset is range.endOffset
        if event.ctrlKey or event.metaKey
          return  controlMeta = yes  if event.keyIdentifier in ["Control", "Meta"]
          char = String.fromCharCode event.which
          if char is "X" then return @setKeyFocus()
          else if char in ["C", "V"] then return
          else if controlMeta then @setKeyFocus()
          controlMeta = no
        else
          @setKeyFocus()

    outputboxElement.addEventListener "keypress", (event) =>
      KD.utils.stopDOMEvent event  if event.target isnt @keyInput.getElement()
    , yes

    @outputbox.on "keydown", (event) =>
      if @mousedownHappened
        @setKeyFocus() unless event.ctrlKey or event.metaKey
        @utils.defer =>
          @mousedownHappened = false

    @outputbox.on "paste", @bound "paste"

    @outputbox.on "drop", (event) =>
      @server.input event.originalEvent.dataTransfer.getData "text/plain"
      KD.utils.stopDOMEvent event

    @updateSize()

    @container.on "mousedown mousemove mouseup mousewheel contextmenu", (event) =>
      @inputHandler.mouseEvent event

    @clientInterface =
      output: (data) =>
        log @inspectString(data) if localStorage?["WebTerm.logRawOutput"] is "true"
        @controlCodeReader.addData data
        if localStorage?["WebTerm.slowDrawing"] is "true"
          @controlCodeInterval ?= window.setInterval =>
            atEnd = @controlCodeReader.process()
            if localStorage?["WebTerm.slowDrawing"] isnt "true"
              atEnd = @controlCodeReader.process() until atEnd
            @screenBuffer.flush()
            if atEnd
              window.clearInterval @controlCodeInterval
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

  keyDown: (event) ->
    @inputHandler.keyDown event

  keyPress: (event) ->
    @inputHandler.keyPress event

  keyUp: (event) ->
    @inputHandler.keyUp event

  setKeyFocus: ->
    @keyInput.getElement().focus()

  setFocused: (value) ->
    @cursor.setFocused value
    if value then KD.utils.defer => @setKeyFocus()

  setSize: (x, y) ->
    return if x is @sizeX and y is @sizeY

    cursorLineIndex  = @screenBuffer.toLineIndex(@cursor.y)
    [@sizeX, @sizeY] = [x, y]
    @screenBuffer.scrollingRegion = [0, y - 1]

    @cursor.moveTo @cursor.x, cursorLineIndex - @screenBuffer.toLineIndex(0)
    @server.setSize x, y if @server

  getCharSizes:->
    sizes =
      width  : @measurebox.getWidth()  or @_mbWidth
      height : @measurebox.getHeight() or @_mbHeight

    [@_mbWidth, @_mbHeight] = [@measurebox.getWidth(), @measurebox.getHeight()]

    return sizes

  updateSize: (force=no) ->

    [swidth, sheight] = [@parent.getWidth()  or @currentWidth,\
                         @parent.getHeight() or @currentHeight]

    return  if not force and \
               swidth is @currentWidth and sheight is @currentHeight

    @scrollToBottom()

    [@currentWidth, @currentHeight] = [swidth, sheight]
    {width, height} = @getCharSizes()

    newWidth  = Math.max width,  Math.floor swidth  / width
    newHeight = Math.max height, Math.floor sheight / height

    @setSize newWidth, newHeight

  windowDidResize: _.throttle (-> @updateSize()), 500

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

    text = text.replace /[ ]/g, "\xA0" # NBSP
    switch @currentCharacterSets[@currentCharacterSetIndex]
      when "0"
        nonBoldStyle = jQuery.extend true, {}, style
        nonBoldStyle.bold = false
        for i in [0..text.length]
          c = text.charCodeAt i
          u = LINE_DRAWING_CHARSET[c - 0x41] ? c
          charStyle = if u >= 0x2300 then nonBoldStyle else style
          newContent.push new WebTerm.StyledText(String.fromCharCode(u), charStyle)
      when "A"
        text = text.replace /#/g, "\xA3" # pound sign
        newContent.push new WebTerm.StyledText(text, style)
      else
        newContent.push new WebTerm.StyledText(text, style)

    newContent.pushAll oldContent.substring(if insert then x else x + text.length)
    @screenBuffer.setLineContent lineIndex, newContent

  writeEmptyText: (length, options) ->
    if not @currentWhitespaceStyle?
      @currentWhitespaceStyle = jQuery.extend true, {}, @currentStyle
      @currentWhitespaceStyle.inverse = false
    @currentWhitespaceStyle
    options ?= {}
    options.style = @currentWhitespaceStyle
    text = ""
    text += "\xA0" for i in [0...length]
    @writeText text, options

  deleteCharacters: (count, options) ->
    x = options?.x ? @cursor.x
    y = options?.y ? @cursor.y
    lineIndex = @screenBuffer.toLineIndex y
    oldContent = @screenBuffer.getLineContent lineIndex
    newContent = oldContent.substring 0, x
    newContent.pushAll oldContent.substring(x + count)
    text = ""
    text += "\xA0" for i in [0...count]
    newContent.push new WebTerm.StyledText(text, oldContent.get(oldContent.length() - 1).style)
    @screenBuffer.setLineContent lineIndex, newContent

  setStyle: (name, value) ->
    @currentStyle = jQuery.extend true, {}, @currentStyle
    @currentStyle[name] = value
    @currentWhitespaceStyle = null

  resetStyle: ->
    @currentStyle = WebTerm.StyledText.DEFAULT_STYLE
    @currentWhitespaceStyle = null

  setCharacterSet: (index, charset) ->
    @currentCharacterSets[index] = charset

  setCharacterSetIndex: (index) ->
    @currentCharacterSetIndex = index

  changeScreenBuffer: (index) ->

  isScrolledToBottom: ->
    @container.scrollTop() + @parent.getHeight() >= @container.prop("scrollHeight") - 3

  scrollToBottom: (animate=no) ->
    return if @isScrolledToBottom()
    @container.stop()
    if animate
      @container.animate { scrollTop: @container.prop("scrollHeight") - @parent.getHeight() }, duration: 200
    else
      @container.scrollTop(@container.prop("scrollHeight") - @parent.getHeight())

  setScrollbackLimit: (limit) ->
    @screenBuffer.scrollbackLimit = limit
    @screenBuffer.flush()

  inspectString: (string) ->
    escaped = string.replace /[\x00-\x1f\\]/g, (character) ->
      special = SPECIAL_CHARS[character]
      return special if special
      hex = character.charCodeAt(0).toString(16).toUpperCase()
      hex = "0" + hex if hex.length is 1
      '\\x' + hex
    '"' + escaped.replace('"', '\\"') + '"'

  paste: (event) =>
    KD.utils.stopDOMEvent event
    @server.input event.originalEvent.clipboardData.getData "text/plain"
    @setKeyFocus()
