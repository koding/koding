class IDE.ShortcutsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'key-mappings'

    super options, data

    shortcuts = @getShortcuts()
    apples    = [ "MacIntel", "MacPPC", "Mac68K", "Macintosh", "iPad" ]
    isApple   = apples.indexOf(navigator.platform) > -1

    for title, mapping of shortcuts
      container = new KDCustomHTMLView
        cssClass: 'container'
        partial : "<p>#{title}</p>"

      for description, shortcut of mapping
        metaKey   = 'Ctrl'
        key       = 'Others'

        if isApple
          metaKey = 'Cmd'
          key     = 'Apple'

        shortcut  = shortcut[key]  if typeof shortcut is 'object'
        shortcut  = shortcut.replace 'Meta', metaKey

        container.addSubView new IDE.ShortcutView {}, { shortcut, description }

      @addSubView container

  getShortcuts: ->

    # FIXME
    # get these from KD.appClasses.IDE.options.keyBindings
    # and sanitize them and keep this only in one place - SY
    'Workspace Shortcuts':
      'Split vertically'       : 'Ctrl-Alt-V'
      'Split horizontally'     : 'Ctrl-Alt-H'
      'Merge splitview'        : 'Ctrl-Alt-M'
      'Open new file'          : 'Ctrl-Alt-N'
      'Open new terminal'      : 'Ctrl-Alt-T'
      'Open new browser'       : 'Ctrl-Alt-B'
      'Open new drawing board' : 'Ctrl-Alt-D'
      'Collapse sidebar'       : 'Ctrl-Alt-C'
      'Expand sidebar'         : 'Ctrl-Alt-E'
      'Fullscreen'             : 'Meta-Enter'
      'Close tab'              : 'Ctrl-Alt-W'
      'Go to left tab'         : 'Ctrl-Alt-['
      'Go to right tab'        : 'Ctrl-Alt-]'
      'Go to tab number 1'     : 'Ctrl-Alt-1'
      'Go to tab number 2'     : 'Ctrl-Alt-2'
      'Go to tab number 3'     : 'Ctrl-Alt-3'
      'Go to tab number 4'     : 'Ctrl-Alt-4'
      'Go to tab number 5'     : 'Ctrl-Alt-5'
      'Go to tab number 6'     : 'Ctrl-Alt-6'
      'Go to tab number 7'     : 'Ctrl-Alt-7'
      'Go to tab number 8'     : 'Ctrl-Alt-8'
      'Go to tab number 9'     : 'Ctrl-Alt-9'

    'Editor Shortcuts':
      'Save'                   : 'Meta-S'
      'Find'                   : 'Meta-F'
      'Find next'              : { Others: 'Ctrl-K',         Apple: 'Meta-G'       }
      'Find previous'          : { Others: 'Ctrl-Shift-K',   Apple: 'Meta-Shift-G' }
      'Find and replace'       : 'Meta-Shift-F'
      'Go to top'              : { Others: 'Ctrl-Home',      Apple: 'Meta-Up'   }
      'Go to bottom'           : { Others: 'Ctrl-End',       Apple: 'Meta-Down' }
      'Go line up'             : 'Ctrl-N'
      'Go line down'           : 'Ctrl-P'
      'Go to left'             : 'Ctrl-B'
      'Go to right'            : 'Ctrl-F'
      'Go to end'              : { Others: 'Ctrl-End',       Apple: 'Meta-Down' }
      'Go to line'             : 'Meta-G'
      'Go to line'             : 'Meta-L'
      'Go to line end'         : { Others: 'Alt-Right',      Apple: 'Meta-Right'}
      'Go to line end'         : { Others: 'End',            Apple: 'Ctrl-E'    }
      'Go to line start'       : { Others: 'Alt-Left',       Apple: 'Meta-Left' }
      'Go to line start'       : { Others: 'End',            Apple: 'Ctrl-A'    }
      'Go to matching bracket' : 'Ctrl-P'
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
      'Fold all'               : { Others: 'Alt-0',          Apple: 'Meta-Alt-0' }
      'Fold selection'         : { Others: 'Alt-L',          Apple: 'Meta-Alt-L' }
      'Unfold'                 : { Others: 'Alt-Shift-L',    Apple: 'Meta-Alt-Shift-L' }
      'Unfold all'             : { Others: 'Alt-Shift-0',    Apple: 'Meta-Alt-Shift-0' }
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
      'Select word left'       : { Others: 'Ctrl-Shift-Left',  Apple: 'Alt-Shift-Up'     }
      'Select word right'      : { Others: 'Ctrl-Shift-Right', Apple: 'Alt-Shift-Up'     }
      'Toggle comment'         : 'Meta-/'

      # NOT YET IMPLEMENTED
      # 'Save As'                : 'Meta-Shift-S'
      # 'Save All'               : 'Meta-Alt-S'
      # 'Preview'                : 'Meta-Shift-P'
      # 'Settings'               : 'Ctrl-,'
