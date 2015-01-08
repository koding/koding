class EditorMacroView extends KDModalView
  # we copy paste that markdown from https://github.com/ajaxorg/ace/wiki/Default-Keyboard-Shortcuts
  # if we want to update keybindings, just change the keyBindings markdown content.
  keyBindings = """
    | PC (Windows/Linux)             | Mac                            | Action                         |
    |:-------------------------------|:-------------------------------|:-------------------------------|
    | Ctrl-S | Command-Save | save file |
    | Ctrl-Shift-S | Command-Shift-S | save As... |
    | Ctrl-Alt-S | Command-Option-S | save All |
    | Ctrl-W | Ctrl-W, | close file |
    | Ctrl-Alt-Up | Ctrl-Option-Up | add multi-cursor above |
    | Ctrl-Alt-Down | Ctrl-Option-Down | add multi-cursor below |
    | Ctrl-Alt-Right | Ctrl-Option-Right | add next occurrence to multi-selection |
    | Ctrl-Alt-Left | Ctrl-Option-Left | add previous occurrence to multi-selection |
    | Ctrl-Shift-U | Ctrl-Shift-U | change to lower case |
    | Ctrl-U | Ctrl-U | change to upper case |
    | Alt-Shift-Down | Command-Option-Down | copy lines down |
    | Alt-Shift-Up | Command-Option-Up | copy lines up |
    | Delete |  | delete |
    | Ctrl-Shift-D | Command-Shift-D | duplicate selection |
    | Ctrl-F | Command-F | find |
    | Ctrl-K | Command-G | find next |
    | Ctrl-Shift-K | Command-Shift-G | find previous |
    | Alt-0 | Command-Option-0 | fold all |
    | Alt-L, Ctrl-F1 | Command-Option-L, Command-F1 | fold selection |
    | Down | Down, Ctrl-N | go line down |
    | Up | Up, Ctrl-P | go line up |
    | Ctrl-End | Command-End, Command-Down | go to end |
    | Left | Left, Ctrl-B | go to left |
    | Ctrl-L | Command-L | go to line |
    | Alt-Right, End | Command-Right, End, Ctrl-E | go to line end |
    | Alt-Left, Home | Command-Left, Home, Ctrl-A | go to line start |
    | Ctrl-P |  | go to matching bracket |
    | PageDown | Option-PageDown, Ctrl-V | go to page down |
    | PageUp | Option-PageUp | go to page up |
    | Right | Right, Ctrl-F | go to right |
    | Ctrl-Home | Command-Home, Command-Up | go to start |
    | Ctrl-Left | Option-Left | go to word left |
    | Ctrl-Right | Option-Right | go to word right |
    | Tab | Tab | indent |
    | Ctrl-Alt-E |  | macros recording |
    | Ctrl-Shift-E | Command-Shift-E | macros replay |
    | Alt-Down | Option-Down | move lines down |
    | Alt-Up | Option-Up | move lines up |
    | Ctrl-Alt-Shift-Up | Ctrl-Option-Shift-Up | move multicursor from current line to the line above |
    | Ctrl-Alt-Shift-Down | Ctrl-Option-Shift-Down | move multicursor from current line to the line below |
    | Shift-Tab | Shift-Tab | outdent |
    | Insert | Insert | overwrite |
    | Ctrl-Shift-Z, Ctrl-Y | Command-Shift-Z, Command-Y | redo |
    | Ctrl-Alt-Shift-Right | Ctrl-Option-Shift-Right | remove current occurrence from multi-selection and move to next |
    | Ctrl-Alt-Shift-Left | Ctrl-Option-Shift-Left | remove current occurrence from multi-selection and move to previous |
    | Ctrl-D | Command-D | remove line |
    | Alt-Delete | Ctrl-K | remove to line end |
    | Alt-Backspace | Command-Backspace | remove to linestart |
    | Ctrl-Backspace | Option-Backspace, Ctrl-Option-Backspace | remove word left |
    | Ctrl-Delete | Option-Delete | remove word right |
    | Ctrl-R | Command-Option-F | replace |
    | Ctrl-Shift-R | Command-Shift-Option-F | replace all |
    | Ctrl-Down | Command-Down | scroll line down |
    | Ctrl-Up |  | scroll line up |
    | Ctrl-A | Command-A | select all |
    | Ctrl-Shift-L | Ctrl-Shift-L | select all from multi-selection |
    | Shift-Down | Shift-Down | select down |
    | Shift-Left | Shift-Left | select left |
    | Shift-End | Shift-End | select line end |
    | Shift-Home | Shift-Home | select line start |
    | Shift-PageDown | Shift-PageDown | select page down |
    | Shift-PageUp | Shift-PageUp | select page up |
    | Shift-Right | Shift-Right | select right |
    | Ctrl-Shift-End | Command-Shift-Down | select to end |
    | Alt-Shift-Right | Command-Shift-Right | select to line end |
    | Alt-Shift-Left | Command-Shift-Left | select to line start |
    | Ctrl-Shift-P |  | select to matching bracket |
    | Ctrl-Shift-Home | Command-Shift-Up | select to start |
    | Shift-Up | Shift-Up | select up |
    | Ctrl-Shift-Left | Option-Shift-Left | select word left |
    | Ctrl-Shift-Right | Option-Shift-Right | select word right |
    | Ctrl-/ | Command-/ | toggle comment |
    | Ctrl-T | Ctrl-T | transpose letters |
    | Ctrl-Z | Command-Z | undo |
    | Alt-Shift-L, Ctrl-Shift-F1 | Command-Option-Shift-L, Command-Shift-F1 | unfold |
    | Alt-Shift-0 | Command-Option-Shift-0 | unfold all |
    | Ctrl-Enter | Command-Enter | enter full screen |
    """

  constructor: (options = {}, data) ->
    keyBindings      = @getKeyboardBindings()
    options.title    = "Editor Key Bindings"
    options.width    = 760
    options.content  = KD.utils.applyMarkdown keyBindings
    options.cssClass = "key-bindings"
    super options, data

  getKeyboardBindings: ->
    rowArray    = keyBindings.split "\n"
    keyBinding  = []
    keyIndex    = @getUserPlatformId()

    for row in rowArray
      splitBinding = row.split "|"
      key          = splitBinding[keyIndex]
      property     =  splitBinding[3]
      unless key.trim() is ""
        binding  = {key, property}
        keyBinding.push binding

    markdown = ""
    keyBinding.map (row)-> markdown += "|#{row.key}|#{row.property}|\n"
    return  markdown

  getUserPlatformId:->
    if KD.utils.isNavigatorApple()
      return  2
    return 1



