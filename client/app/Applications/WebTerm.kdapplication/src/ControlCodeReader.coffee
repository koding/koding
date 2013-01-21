class WebTerm.ControlCodeReader
  constructor: (@terminal, @handler, @nextReader) ->
    @data = ""
    @pos = 0
    @controlCodeOffset = null
    @regexp = new RegExp Object.keys(@handler.map).join("|")

  skip: (lenght) ->
    @pos += lenght

  readChar: ->
    return null if @pos >= @data.length
    c = @data.charAt @pos
    @pos += 1
    c

  readRegexp: (regexp) ->
    result = @data.substring(@pos).match(regexp)
    return null if not result?
    @pos += result[0].length
    result

  readUntil: (regexp) ->
    endPos = @data.substring(@pos).search regexp
    return null if endPos == -1
    string = @data.substring @pos, @pos + endPos
    @pos += endPos
    string

  addData: (newData) ->
    @data += newData

  process: ->
    return false if not @nextReader.process()
    return true if @data.length is 0

    if @controlCodeOffset?
      @controlCodeIncomplete = false
      @handler this
      if @controlCodeIncomplete
        @pos = @controlCodeOffset
        true
      else
        @controlCodeOffset = null
        false
    else
      if (text = @readUntil @regexp)?
        @nextReader.addData text
        @nextReader.process()
        @controlCodeOffset = @pos
        false
      else
        @nextReader.addData @data.substring(@pos)
        @data = ""
        @pos = 0
        @nextReader.process()

  incompleteControlCode: ->
    @controlCodeIncomplete = true

  unsupportedControlCode: ->
    warn "Unsupported control code: " + @terminal.inspectString(@data.substring(@controlCodeOffset, @pos))


class WebTerm.TextReader
  constructor: (@terminal) ->
    @data = ""

  addData: (newData) ->
    @data += newData

  process: ->
    return true if @data.length is 0
    while @terminal.cursor.x + @data.length > @terminal.sizeX # line wrapping
      remaining = @terminal.sizeX - @terminal.cursor.x
      @terminal.writeText @data.substring(0, remaining)
      @terminal.lineFeed()
      @terminal.cursor.moveTo 0, @terminal.cursor.y
      @data = @data.substring remaining
    @terminal.writeText @data
    @terminal.cursor.move @data.length, 0
    @data = ""
    true


WebTerm.createAnsiControlCodeReader = (terminal) ->
  switchCharacter = (map) ->
    f = (reader) ->
      c = reader.readChar()
      return reader.incompleteControlCode() if not c?
      handler = map[c]
      return reader.unsupportedControlCode() if not handler?
      handler reader
    f.map = map
    f

  catchCharacter = (handler) ->
    (reader) ->
      c = reader.readChar()
      return reader.incompleteControlCode() if not c?
      handler c

  catchParameters = (regexp, map) ->
    (reader) ->
      result = reader.readRegexp regexp
      return reader.incompleteControlCode() if not result?
      [_, prefix, paramString, command] = result
      rawParams = if paramString.lenght is 0
        []
      else
        for p in paramString.split ";"
          if p.length is 0 then null else p
      params = for p in rawParams
        if p then parseInt p, 10 else null
      params.raw = rawParams

      if map instanceof Function
        map params, reader
        return

      handler = map[prefix + command]
      return reader.unsupportedControlCode() if not handler?
      handler params, reader

  switchParameter = (index, map) ->
    (params, reader) ->
      handler = map[params[index] ? 0]
      return reader.unsupportedControlCode() if not handler?
      handler params

  switchRawParameter = (index, map) ->
    (params, reader) ->
      handler = map[params.raw[index]]
      return reader.unsupportedControlCode() if not handler?
      handler params

  eachParameter = (map) ->
    f = (params, reader) ->
      while params.length > 0
        handler = map[params[0] ? 0]
        return reader.unsupportedControlCode() if not handler?
        handler params, reader
        params.shift()
    f.addRange = (from, to, handler) ->
      map[i] = handler for i in [from..to]
      f
    f

  ignored = (str) ->
    -> log "Ignored: " + str

  originMode = false

  getOrigin = ->
    if originMode
      terminal.screenBuffer.scrollingRegion[0]
    else
      0

  insertOrDeleteLines = (amount) ->
    previousScrollingRegion = terminal.screenBuffer.scrollingRegion
    terminal.screenBuffer.scrollingRegion = [terminal.cursor.y, terminal.screenBuffer.scrollingRegion[1]]
    terminal.screenBuffer.scroll -amount
    terminal.screenBuffer.scrollingRegion = previousScrollingRegion

  initCursorControlHandler = ->
    switchCharacter
      "\x00": -> # ignored
      "\x08": -> terminal.cursor.move -1, 0 # BS
      "\x09": -> terminal.cursor.moveTo terminal.cursor.x - (terminal.cursor.x % 8) + 8, terminal.cursor.y # TAB
      "\x0A": -> terminal.lineFeed() # LF
      "\x0B": -> terminal.lineFeed() # VT
      "\x0D": -> terminal.cursor.moveTo 0, terminal.cursor.y # CR

  initEscapeSequenceHandler = ->
    switchCharacter
      "\x07": ignored "bell"
      "\x0E": -> terminal.setCharacterSetIndex 1
      "\x0F": -> terminal.setCharacterSetIndex 0
      "\x1B": switchCharacter # ESC
        "D": -> terminal.lineFeed()
        "E": -> terminal.lineFeed(); terminal.cursor.moveTo 0, terminal.cursor.y
        "M": -> terminal.reverseLineFeed()
        "P": catchParameters(/^()(.*?)(\x1B\\)/, {}) # DCS
        "#": switchCharacter
          "8": ->
            terminal.screenBuffer.clear()
            text = ""
            text += "E" for x in [0...terminal.sizeX]
            terminal.writeText text, x: 0, y: y for y in [0...terminal.sizeY]
        "(": catchCharacter (c) -> terminal.setCharacterSet 0, c
        ")": catchCharacter (c) -> terminal.setCharacterSet 1, c
        "*": catchCharacter (c) -> terminal.setCharacterSet 2, c
        "+": catchCharacter (c) -> terminal.setCharacterSet 3, c
        "-": catchCharacter (c) -> terminal.setCharacterSet 1, c
        ".": catchCharacter (c) -> terminal.setCharacterSet 2, c
        "/": catchCharacter (c) -> terminal.setCharacterSet 3, c
        "7": -> terminal.cursor.savePosition()
        "8": -> terminal.cursor.restorePosition()
        "=": -> terminal.inputHandler.useApplicationKeypad true
        ">": -> terminal.inputHandler.useApplicationKeypad false
        "[": catchParameters /^(\??)(.*?)([a-zA-Z@`{|])/ # CSI
          "@": (params) -> terminal.writeEmptyText (params[0] ? 1), insert: true
          "A": (params) -> terminal.cursor.move 0, -(params[0] ? 1)
          "B": (params) -> terminal.cursor.move 0, (params[0] ? 1)
          "C": (params) -> terminal.cursor.move (params[0] ? 1), 0
          "D": (params) -> terminal.cursor.move -(params[0] ? 1), 0
          "G": (params) -> terminal.cursor.moveTo (params[0] ? 1) - 1, terminal.cursor.y
          "H": (params) -> terminal.cursor.moveTo (params[1] ? 1) - 1, getOrigin() + (params[0] ? 1) - 1
          "I": (params) -> terminal.cursor.moveTo (Math.floor(terminal.cursor.x / 8) + (params[0] ? 1)) * 8, terminal.cursor.y unless params[0] == 0
          "J": switchParameter 0
            0: ->
              terminal.writeEmptyText terminal.sizeX - terminal.cursor.x
              terminal.writeEmptyText terminal.sizeX, x: 0, y: y for y in [(terminal.cursor.y + 1)...terminal.sizeY]
            1: ->
              terminal.writeEmptyText terminal.sizeX, x: 0, y: y for y in [0...terminal.cursor.y]
              terminal.writeEmptyText terminal.cursor.x + 1, x: 0
            2: -> terminal.screenBuffer.clear()
          "K": switchParameter 0
            0: -> terminal.writeEmptyText terminal.sizeX - terminal.cursor.x
            1: -> terminal.writeEmptyText terminal.cursor.x + 1, x: 0
            2: -> terminal.writeEmptyText terminal.sizeX, x: 0
          "L": (params) -> insertOrDeleteLines (params[0] ? 1)
          "M": (params) -> insertOrDeleteLines -(params[0] ? 1)
          "P": (params) -> terminal.deleteCharacters params[0] ? 1
          "S": (params) -> terminal.screenBuffer.scroll (params[0] ? 1)
          "T": (params) -> terminal.screenBuffer.scroll -(params[0] ? 1)
          "X": (params) -> terminal.writeEmptyText params[0] ? 1
          "Z": (params) -> terminal.cursor.moveTo (Math.ceil(terminal.cursor.x / 8) - (params[0] ? 1)) * 8, terminal.cursor.y unless params[0] == 0
          "c": switchRawParameter 0
            0:   -> terminal.server.controlSequence "\x1B[>?1;2c"
            ">": -> terminal.server.controlSequence "\x1B[>0;261;0c"
            ">0": -> terminal.server.controlSequence "\x1B[>0;261;0c"
          "d": (params) -> terminal.cursor.moveTo terminal.cursor.x, getOrigin() + (params[0] ? 1) - 1
          "f": (params) -> terminal.cursor.moveTo (params[1] ? 1) - 1, getOrigin() + (params[0] ? 1) - 1
          "h": eachParameter
            4:    ignored "insert mode"
            20:   ignored "automatic newline"
          "?h": eachParameter
            1:    -> terminal.inputHandler.useApplicationKeypad true
            3:    -> terminal.screenBuffer.clear(); terminal.setSize 132, terminal.sizeY; terminal.cursor.moveTo 0, 0
            4:    ignored "smooth scroll"
            5:    ignored "reverse video"
            6:    -> originMode = true
            7:    ignored "wraparound mode"
            8:    ignored "auto-repeat keys"
            9:    -> terminal.inputHandler.setMouseMode true, false, false
            12:   ignored "start blinking cursor"
            25:   -> terminal.cursor.setVisibility true
            40:   ignored "allow 80 to 132 mode"
            42:   ignored "enable nation replacement character sets"
            45:   ignored "reverse-wraparound mode"
            47:   -> terminal.changeScreenBuffer 1
            1000: -> terminal.inputHandler.setMouseMode true, true, false
            1001: -> terminal.inputHandler.setMouseMode true, true, false
            1002: -> terminal.inputHandler.setMouseMode true, true, true
            1003: -> terminal.inputHandler.setMouseMode true, true, true
            1015: ignored "enable urxvt mouse mode"
            1034: ignored "interpret meta key"
            1047: -> terminal.changeScreenBuffer 1
            1048: -> terminal.cursor.savePosition()
            1049: -> terminal.cursor.savePosition(); terminal.changeScreenBuffer 1
          "l": eachParameter
            4:    ignored "replace mode"
            20:   ignored "normal linefeed"
          "?l": eachParameter
            1:    -> terminal.inputHandler.useApplicationKeypad false
            3:    -> terminal.screenBuffer.clear(); terminal.setSize 80, terminal.sizeY; terminal.cursor.moveTo 0, 0
            4:    ignored "jump scroll"
            5:    ignored "normal video"
            6:    -> originMode = false
            7:    ignored "no wraparound mode"
            8:    ignored "no auto-repeat keys"
            9:    -> terminal.inputHandler.setMouseMode false, false, false
            12:   ignored "stop blinking cursor"
            25:   -> terminal.cursor.setVisibility false
            40:   ignored "disallow 80 to 132 mode"
            42:   ignored "disable nation replacement character sets"
            45:   ignored "no reverse-wraparound mode"
            47:   -> terminal.changeScreenBuffer 0
            1000: -> terminal.inputHandler.setMouseMode false, false, false
            1001: -> terminal.inputHandler.setMouseMode false, false, false
            1002: -> terminal.inputHandler.setMouseMode false, false, false
            1003: -> terminal.inputHandler.setMouseMode false, false, false
            1015: ignored "disable urxvt mouse mode"
            1034: ignored "don't interpret meta key"
            1047: -> terminal.changeScreenBuffer 0
            1048: -> terminal.cursor.restorePosition()
            1049: -> terminal.changeScreenBuffer 0; terminal.cursor.moveTo 0, terminal.sizeY - 1
          "m": eachParameter
            0:  -> terminal.resetStyle()
            1:  -> terminal.setStyle "bold", true
            4:  -> terminal.setStyle "underlined", true
            7:  -> terminal.setStyle "inverse", true
            22: -> terminal.setStyle "bold", false
            24: -> terminal.setStyle "underlined", false
            27: -> terminal.setStyle "inverse", false
            38: switchParameter 1
              5: (params) -> terminal.setStyle "textColor", params[2]; params.shift(); params.shift()
            39: -> terminal.setStyle "textColor", null
            48: switchParameter 1
              5: (params) -> terminal.setStyle "backgroundColor", params[2]; params.shift(); params.shift()
            49: -> terminal.setStyle "backgroundColor", null
          .addRange(30, 37, (params) -> terminal.setStyle "textColor", params[0] - 30)
          .addRange(40, 47, (params) -> terminal.setStyle "backgroundColor", params[0] - 40)
          .addRange(90, 97, (params) -> terminal.setStyle "textColor", params[0] - 90 + 8)
          .addRange(100, 107, (params) -> terminal.setStyle "backgroundColor", params[0] - 100 + 8)
          "r": (params) -> terminal.screenBuffer.scrollingRegion = [(params[0] ? 1) - 1, (params[1] ? terminal.sizeY) - 1]
          "?r": ignored "restore mode values"
          "p": switchRawParameter 0
            "!": -> # soft reset
              terminal.cursor.setVisibility true
              originMode = false
              terminal.changeScreenBuffer 0
              terminal.inputHandler.useApplicationKeypad false
          "?s": ignored "save mode values"
        "]": catchParameters /()(.*?)(\x07|\x1B\\)/, switchParameter 0 # OSC
          0: (params) -> terminal.setTitleCallback? params.raw[1]
          1: ignored "icon name"
          2: (params) -> terminal.setTitleCallback? params.raw[1]
          4: (params) ->
            parts = params.raw[2].match(/^rgb:(..)\/(..)\/(..)$/)
            terminal.defineColor params[1], "##{parts[1]}#{parts[2]}#{parts[3]}"

  return new WebTerm.ControlCodeReader(terminal, initCursorControlHandler(),
    new WebTerm.ControlCodeReader(terminal, initEscapeSequenceHandler(),
      new WebTerm.TextReader(terminal)
    )
  )