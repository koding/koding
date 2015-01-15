ShortcutView = require './shortcutview'


class ShortcutsView extends KDCustomScrollView

  constructor: (options = {}, data) ->

    super options, data

    @wrapper.setClass 'key-mappings'

    shortcuts = @getShortcuts()
    isNavigatorApple = KD.utils.isNavigatorApple()

    for title, mapping of shortcuts
      container = new KDCustomHTMLView
        cssClass: 'container'
        partial : "<p>#{title}</p>"

      for description, shortcut of mapping
        metaKey   = 'Ctrl'
        key       = 'Others'

        if isNavigatorApple
          metaKey = 'Cmd'
          key     = 'Apple'

        shortcut  = shortcut[key]  if typeof shortcut is 'object'
        shortcut  = shortcut.replace 'Meta', metaKey

        container.addSubView new ShortcutView {}, { shortcut, description }

      @wrapper.addSubView container

  getShortcuts: ->

    # FIXME
    # get these from KD.appClasses.IDE.options.keyBindings
    # and sanitize them and keep this only in one place - SY
    'Workspace Shortcuts':
      'Split vertically'       : 'Ctrl-Alt-V'
      'Split horizontally'     : 'Ctrl-Alt-H'
      'Merge splitview'        : 'Ctrl-Alt-M'
      'Find file by name'      : 'Ctrl-Alt-O'
      'Search in all files'    : 'Ctrl-Alt-F'
      'Open new file'          : 'Ctrl-Alt-N'
      'Open new terminal'      : 'Ctrl-Alt-T'
      'Open new drawing board' : 'Ctrl-Alt-D'
      'Toggle sidebar'         : 'Ctrl-Alt-K'
      'Fullscreen'             : 'Meta-Shift-Enter'
      'Close tab'              : 'Ctrl-Alt-W'
      'Go to left tab'         : 'Ctrl-Alt-['
      'Go to right tab'        : 'Ctrl-Alt-]'
      'Go to tab number 1'     : { Others: 'Ctrl-1', Apple: 'Meta-1' }
      'Go to tab number 2'     : { Others: 'Ctrl-2', Apple: 'Meta-2' }
      'Go to tab number 3'     : { Others: 'Ctrl-3', Apple: 'Meta-3' }
      'Go to tab number 4'     : { Others: 'Ctrl-4', Apple: 'Meta-4' }
      'Go to tab number 5'     : { Others: 'Ctrl-5', Apple: 'Meta-5' }
      'Go to tab number 6'     : { Others: 'Ctrl-6', Apple: 'Meta-6' }
      'Go to tab number 7'     : { Others: 'Ctrl-7', Apple: 'Meta-7' }
      'Go to tab number 8'     : { Others: 'Ctrl-8', Apple: 'Meta-8' }
      'Go to tab number 9'     : { Others: 'Ctrl-9', Apple: 'Meta-9' }

    'Editor Shortcuts':
      'Save'                   : 'Meta-S'
      'Save as'                : 'Meta-Shift-S'
      'Save all'               : 'Ctrl-Alt-S'
      'Find'                   : 'Meta-F'
      'Find next'              : { Others: 'Ctrl-K',         Apple: 'Meta-G'       }
      'Find previous'          : { Others: 'Ctrl-Shift-K',   Apple: 'Meta-Shift-G' }
      'Find and replace'       : 'Meta-Shift-F'
      'Preview file'           : 'Ctrl-Alt-P'
      'Go to top'              : { Others: 'Ctrl-Home',      Apple: 'Meta-Up'   }
      'Go to bottom'           : { Others: 'Ctrl-End',       Apple: 'Meta-Down' }
      'Go to next line'        : 'Ctrl-N'
      'Go to previous line'    : 'Ctrl-P'
      'Go to left'             : 'Ctrl-B'
      'Go to right'            : 'Ctrl-F'
      'Go to line'             : 'Meta-G'
      'Go to line start'       : { Others: 'Alt-Left',       Apple: 'Meta-Left' }
      'Go to line start'       : { Others: 'Home',           Apple: 'Ctrl-A'    }
      'Go to line end'         : { Others: 'Alt-Right',      Apple: 'Meta-Right'}
      'Go to line end'         : { Others: 'End',            Apple: 'Ctrl-E'    }
      'Go to page down'        : 'Ctrl-V'
      'Go to word left'        : { Others: 'Ctrl-Left',      Apple: 'Alt-Left'  }
      'Go to word right'       : { Others: 'Ctrl-Right',    Apple: 'Alt-Right' }
      'Add multi-cursor above' : 'Ctrl-Alt-Up'
      'Add multi-cursor below' : 'Ctrl-Alt-Down'
      'Add next occurrence to multi-selection'     : 'Ctrl-Alt-Right'
      'Add previous occurrence to multi-selection' : 'Ctrl-Alt-Left'
      'Change to lower case'   : 'Ctrl-Shift-U'
      'Change to upper case'   : 'Ctrl-U'
      'Copy lines down'        : { Others: 'Alt-Shift-Down', Apple: 'Meta-Alt-Down' }
      'Copy lines up'          : { Others: 'Alt-Shift-Up',   Apple: 'Meta-Alt-Up'   }
      'Move lines down'        : 'Alt-Down'
      'Move lines up'          : 'Alt-Up'
      'Duplicate selection'    : 'Meta-Shift-D'
      'Toggle folding'         : { Others: 'Alt-L',          Apple: 'Meta-Alt-L' }
      'Move multicursor from current line to the line above': 'Ctrl-Alt-Shift-Up'
      'Move multicursor from current line to the line below': 'Ctrl-Alt-Shift-Down'
      'Indent'                 : 'Tab'
      'Outdent'                : 'Shift-Tab'
      'Redo'                   : 'Meta-Y'
      'Redo'                   : 'Meta-Shift-Z'
      'Undo'                   : 'Meta-Z'
      'Remove current occurrence from multi-selection and move to next'    : 'Ctrl-Alt-Shift-Right'
      'Remove current occurrence from multi-selection and move to previous': 'Ctrl-Alt-Shift-Left'
      'Remove line'            : 'Meta-D'
      'Remove to line end'     : { Others: 'Alt-Del',          Apple: 'Ctrl-K'         }
      'Remove to line start'   : { Others: 'Alt-Backspace',    Apple: 'Meta-Backspace' }
      'Remove word left'       : { Others: 'Ctrl-Backspace',   Apple: 'Alt-Backspace'  }
      'Remove word right'      : { Others: 'Ctrl-Del',         Apple: 'Alt-Del'        }
      'Select all'             : 'Meta-A'
      'Select all from multi-selection' : 'Ctrl-Shift-L'
      'Select up'              : 'Shift-Up'
      'Select down'            : 'Shift-Down'
      'Select left'            : 'Shift-Left'
      'Select right'           : 'Shift-Right'
      'Select to line end'     : { Others: 'Shift-End',        Apple: 'Meta-Shift-Right' }
      'Select to line start'   : { Others: 'Shift-Home',       Apple: 'Meta-Shift-Left'  }
      'Select to end'          : { Others: 'Ctrl-Shift-End',   Apple: 'Meta-Shift-Down'  }
      'Select to start'        : { Others: 'Ctrl-Shift-Home',  Apple: 'Meta-Shift-Up'    }
      'Select word left'       : { Others: 'Ctrl-Shift-Left',  Apple: 'Alt-Shift-Left'   }
      'Select word right'      : { Others: 'Ctrl-Shift-Right', Apple: 'Alt-Shift-Right'  }
      'Toggle comment'         : 'Meta-/'


module.exports = ShortcutsView
