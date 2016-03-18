module.exports = class InputHandler

  ESC = '\x1B'
  CSI = ESC + '['
  SS3 = ESC + 'O'

  KEY_SEQUENCES:
    8:   '\x7F'                 # Backspace
    9:   '\t'                   # Tab
    13:  '\r'                   # Enter
    27:  ESC                    # Escape
    33:  CSI + '5~'             # Page Up
    34:  CSI + '6~'             # Page Down
    35:  SS3 + 'F'              # End
    36:  SS3 + 'H'              # Home
    37:  [CSI + 'D', SS3 + 'D'] # Left Arrow
    38:  [CSI + 'A', SS3 + 'A'] # Up Arrow
    39:  [CSI + 'C', SS3 + 'C'] # Right Arrow
    40:  [CSI + 'B', SS3 + 'B'] # Down Arrow
    46:  CSI + '3~'             # Delete
    112: SS3 + 'P'              # F1
    113: SS3 + 'Q'              # F2
    114: SS3 + 'R'              # F3
    115: SS3 + 'S'              # F4
    116: CSI + '15~'            # F5
    117: CSI + '17~'            # F6
    118: CSI + '18~'            # F7
    119: CSI + '19~'            # F8
    120: CSI + '20~'            # F9
    121: CSI + '21~'            # F10
    122: CSI + '23~'            # F11
    123: CSI + '24~'            # F12

  constructor: (@terminal) ->

    @applicationKeypad = false
    @trackMouseDown = false
    @trackMouseUp = false
    @trackMouseHold = false
    @previousMouseX = -1
    @previousMouseY = -1


  isTerminalReady: -> @terminal.server?


  keyDown: (event) ->

    return unless @isTerminalReady()

    @terminal.scrollToBottom()
    @terminal.cursor.resetBlink()

    if event.ctrlKey
      unless event.shiftKey or event.altKey or event.keyCode < 64
        @terminal.server.controlSequence String.fromCharCode(event.keyCode - 64)
        event.preventDefault()
      return

    seq = @KEY_SEQUENCES[event.keyCode]
    if Array.isArray seq
      seq = seq[if @applicationKeypad then 1 else 0]

    if seq?
      @terminal.server.controlSequence seq
      event.preventDefault()

  keyPress: (event) ->

    if event.metaKey
      switch event.charCode
        when 97, 114, 118, 119
          # meta-C is copy
          # meta-R is reload
          # meta-V is paste
          # meta-W is window.close
          return

    unless (event.ctrlKey and not event.altKey) or event.charCode is 0
      @terminal.server?.input String.fromCharCode(event.charCode)

    event.preventDefault()


  keyUp: (event) ->

  setMouseMode: (@trackMouseDown, @trackMouseUp, @trackMouseHold) ->

    @terminal.outputbox.css 'cursor', if @trackMouseDown then 'pointer' else 'text'


  mouseEvent: (event) ->

    offset = @terminal.container.offset()
    x = Math.floor((event.originalEvent.clientX - offset.left + @terminal.container.scrollLeft()) * @terminal.sizeX / @terminal.container.prop('scrollWidth'))
    y = Math.floor((event.originalEvent.clientY - offset.top + @terminal.container.scrollTop()) * @terminal.screenBuffer.lineDivs.length / @terminal.container.prop('scrollHeight') - @terminal.screenBuffer.lineDivs.length + @terminal.sizeY)

    return if x < 0 or x >= @terminal.sizeX or y < 0 or y >= @terminal.sizeY

    eventCode = 0
    eventCode |= 4   if event.shiftKey
    eventCode |= 8   if event.altKey
    eventCode |= 16  if event.ctrlKey

    switch event.type
      when 'mousedown'
        return if not @trackMouseDown
        eventCode |= event.which - 1
      when 'mouseup'
        return if not @trackMouseUp
        eventCode |= 3
      when 'mousemove'
        return if not @trackMouseHold or event.which is 0 or (x is @previousMouseX and y is @previousMouseY)
        eventCode |= event.which - 1
        eventCode += 32
      when 'wheel'
        return not @trackMouseDown
        eventCode |= if event.originalEvent.wheelDelta > 0 then 0 else 1
        eventCode += 64
      when 'contextmenu'
        return not @trackMouseDown
    @previousMouseX = x
    @previousMouseY = y
    @terminal.server.controlSequence CSI + 'M' + String.fromCharCode(eventCode + 32) + String.fromCharCode(x + 33) + String.fromCharCode(y + 33)
    event.preventDefault()


  useApplicationKeypad: (value) -> @applicationKeypad = value
