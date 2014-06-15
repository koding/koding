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
      'Ctrl-Alt-v'   : 'split vertically'
      'Ctrl-Alt-h'   : 'split horizontally'
      'Ctrl-Alt-m'   : 'merge splitview'
      'Ctrl-Alt-n'   : 'create new file'
      'Ctrl-Alt-c'   : 'collapse sidebar'
      'Ctrl-Alt-e'   : 'expand sidebar'
      'Ctrl-Alt-['   : 'go to left tab'
      'Ctrl-Alt-]'   : 'go to right tab'
      'Ctrl-Alt-1'   : 'go to tab number'
      'Ctrl-Alt-2'   : 'go to tab number'
      'Ctrl-Alt-3'   : 'go to tab number'
      'Ctrl-Alt-4'   : 'go to tab number'
      'Ctrl-Alt-5'   : 'go to tab number'
      'Ctrl-Alt-6'   : 'go to tab number'
      'Ctrl-Alt-7'   : 'go to tab number'
      'Ctrl-Alt-8'   : 'go to tab number'
      'Ctrl-Alt-9'   : 'go to tab number'

    'Editor Shortcuts':
      'Ctrl-S'       : 'save'
      'Ctrl-Shift-S' : 'saveAs'
      'Ctrl-F'       : 'find'
      'Ctrl-Shift-F' : 'replace'
      'Ctrl-Shift-P' : 'preview'
      'Ctrl-Enter'   : 'fullscreen'
      'Ctrl-G'       : 'gotoLine'
      'Ctrl-L'       : 'gotoLine'
      'Ctrl-Alt-S'   : 'saveAll'
      'Ctrl-W'       : 'closeTab'
      'Ctrl-,'       : 'settings'
