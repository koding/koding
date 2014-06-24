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
        metaKey  = if isApple then  'Cmd' else 'Ctrl'
        shortcut = shortcut.replace 'Meta', metaKey

        container.addSubView new IDE.ShortcutView {}, { shortcut, description }

      @addSubView container

  getShortcuts: ->
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
      'Find and Replace'       : 'Meta-Shift-F'
      'Go to Line'             : 'Meta-G'
      'Go to Line'             : 'Meta-L'

      # 'Ctrl-Shift-S' : 'saveAs'
      # 'Ctrl-Shift-P' : 'preview'
      # 'Ctrl-Alt-S'   : 'saveAll'
      # 'Ctrl-W'       : 'closeTab'
      # 'Ctrl-,'       : 'settings'
