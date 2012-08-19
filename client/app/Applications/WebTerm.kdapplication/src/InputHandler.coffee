class WebTerm.InputHandler
  ESC = "\x1B";
  CSI = ESC + "[";
  OSC = ESC + "]";
  SS3 = ESC + "O";

  KEY_SEQUENCES:
    8:   "\x7F"                 # Backspace
    9:   "\t"                   # Tab
    13:  "\r"                   # Enter
    27:  ESC                    # Escape
    33:  CSI + "5~"             # Page Up
    34:  CSI + "6~"             # Page Down
    35:  SS3 + "F"              # End
    36:  SS3 + "H"              # Home
    37:  [CSI + "D", SS3 + "D"] # Left Arrow
    38:  [CSI + "A", SS3 + "A"] # Up Arrow
    39:  [CSI + "C", SS3 + "C"] # Right Arrow
    40:  [CSI + "B", SS3 + "B"] # Down Arrow
    46:  CSI + "3~"             # Delete
    112: SS3 + "P"              # F1
    113: SS3 + "Q"              # F2
    114: SS3 + "R"              # F3
    115: SS3 + "S"              # F4
    116: CSI + "15~"            # F5
    117: CSI + "17~"            # F6
    118: CSI + "18~"            # F7
    119: CSI + "19~"            # F8
    120: CSI + "20~"            # F9
    121: CSI + "21~"            # F10
    122: CSI + "23~"            # F11
    123: CSI + "24~"            # F12
  
  constructor: (@terminal) ->
    @applicationKeypad = false
    @mouseClickTracking = false
    
  keyDown: (event) ->
    @terminal.scrollToBottom()
    @terminal.cursor.resetBlink()
    
    if event.ctrlKey
      unless event.shiftKey or event.keyCode < 64
        @terminal.server.input String.fromCharCode(event.keyCode - 64)
        event.preventDefault()
      return
    
    seq = @KEY_SEQUENCES[event.keyCode]
    if seq instanceof Array
      seq = seq[if @applicationKeypad then 1 else 0]
    
    if seq?
      @terminal.server.input seq
      event.preventDefault()
  
  keyPress: (event) ->
    unless event.ctrlKey or event.charCode is 0
      @terminal.server.input String.fromCharCode(event.charCode)
    event.preventDefault()
  
  keyUp: (event) ->
    # nothing to do
  
  mouseDown: (event) ->
    @mouseEvent event
  
  mouseUp: (event) ->
    @mouseEvent event
  
  mouseEvent: (event) ->
    offset = @terminal.container.offset()
    x = Math.floor((event.clientX - offset.left + @terminal.container.scrollLeft()) * @terminal.sizeX / @terminal.container.prop("scrollWidth"))
    y = Math.floor((event.clientY - offset.top + @terminal.container.scrollTop()) * @terminal.screenBuffer.lineDivs.length / @terminal.container.prop("scrollHeight") - @terminal.screenBuffer.lineDivs.length + @terminal.sizeY)
    return if x < 0 or x >= @terminal.sizeX or y < 0 or y >= @terminal.sizeY
    return if not @terminal.inSession or not @mouseClickTracking
    type = if event.type is "mousedown" then " " else "#"
    @terminal.server.input CSI + "M" + type + String.fromCharCode(x + 33) + String.fromCharCode(y + 33)
  
  useApplicationKeypad: (value) ->
    @applicationKeypad = value

  useMouseClickTracking: (value) ->
    @mouseClickTracking = value
    @terminal.container.css "cursor", if value then "pointer" else "text"
