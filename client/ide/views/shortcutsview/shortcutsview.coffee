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

      for shortcut, description of mapping
        metaKey  = if isApple then  'Cmd' else 'Ctrl'
        shortcut = shortcut.replace 'Meta', metaKey

        container.addSubView new IDE.ShortcutView {}, { shortcut, description }

      @addSubView container

  getShortcuts: ->
    'Workspace Shortcuts':
      'Ctrl-Alt-V'   : 'Split vertically'
      'Ctrl-Alt-H'   : 'Split horizontally'
      'Ctrl-Alt-M'   : 'Merge splitview'
      'Ctrl-Alt-N'   : 'Open new file'
      'Ctrl-Alt-T'   : 'Open new terminal'
      'Ctrl-Alt-B'   : 'Open new browser'
      'Ctrl-Alt-D'   : 'Open new drawing board'
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
      'Meta-S'       : 'Save'
      'Meta-F'       : 'Find'
      'Meta-Shift-F' : 'Find and Replace'
      'Meta-Enter'   : 'Fullscreen'
      'Meta-G'       : 'Go to Line'
      'Meta-L'       : 'Go to Line'
      # 'Ctrl-Shift-S' : 'saveAs'
      # 'Ctrl-Shift-P' : 'preview'
      # 'Ctrl-Alt-S'   : 'saveAll'
      # 'Ctrl-W'       : 'closeTab'
      # 'Ctrl-,'       : 'settings'
