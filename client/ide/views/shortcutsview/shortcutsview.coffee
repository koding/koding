class IDE.ShortcutsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'key-mappings'

    super options, data

    shortcuts = @getShortcuts()

    for title, mapping of shortcuts
      container = new KDCustomHTMLView
        cssClass: 'container'
        partial : "<p>#{title}</p>"

      for shortcut, description of mapping
        container.addSubView new IDE.ShortcutView {}, { shortcut, description }

      @addSubView container

  getShortcuts: ->
    'Workspace Shortcuts':
      'Ctrl-Alt-V'   : 'Split vertically'
      'Ctrl-Alt-H'   : 'Split horizontally'
      'Ctrl-Alt-M'   : 'Merge splitview'
      'Ctrl-Alt-N'   : 'Create new file'
      'Ctrl-Alt-C'   : 'Collapse sidebar'
      'Ctrl-Alt-E'   : 'Expand sidebar'
      'Ctrl-Alt-W'   : 'Close tab'
      'Ctrl-Alt-['   : 'Go to left tab'
      'Ctrl-Alt-]'   : 'Go to right tab'
      'Ctrl-Alt-1'   : 'Go to tab number'
      'Ctrl-Alt-2'   : 'Go to tab number'
      'Ctrl-Alt-3'   : 'Go to tab number'
      'Ctrl-Alt-4'   : 'Go to tab number'
      'Ctrl-Alt-5'   : 'Go to tab number'
      'Ctrl-Alt-6'   : 'Go to tab number'
      'Ctrl-Alt-7'   : 'Go to tab number'
      'Ctrl-Alt-8'   : 'Go to tab number'
      'Ctrl-Alt-9'   : 'Go to tab number'

    'Editor Shortcuts':
      'Ctrl-S'       : 'Save'
      'Ctrl-F'       : 'Find'
      'Ctrl-Shift-F' : 'Find and Replace'
      'Ctrl-Enter'   : 'Fullscreen'
      'Ctrl-G'       : 'Go to Line'
      'Ctrl-L'       : 'Go to Line'
      # 'Ctrl-Shift-S' : 'saveAs'
      # 'Ctrl-Shift-P' : 'preview'
      # 'Ctrl-Alt-S'   : 'saveAll'
      # 'Ctrl-W'       : 'closeTab'
      # 'Ctrl-,'       : 'settings'
