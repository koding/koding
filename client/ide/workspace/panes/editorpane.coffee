class IDE.EditorPane extends IDE.Pane

  shortcutsShown = no

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'editor-pane', options.cssClass

    super options, data

    @createEditor()

  createEditor: ->
    {file, content} = @getOptions()

    unless file instanceof FSFile
      throw new TypeError 'File must be an instance of FSFile'

    unless content?
      throw new TypeError 'You must pass file content to IDE.EditorPane'

    @addSubView @aceView = new AceView delegate: @getDelegate(), file
    @aceView.ace.once 'ace.ready', =>
      # debugger
      if content is '' and not shortcutsShown
        shortcutsShown = yes
        content =
          """
          Welcome to the new IDE :)
          ======================

          Keyboard shortcuts:
          -------------------

          Editor:
          -------

          "save",       "Ctrl-S"
          "saveAs",     "Ctrl-Shift-S"
          "find",       "Ctrl-F"
          "replace",    "Ctrl-Shift-F"
          "preview",    "Ctrl-Shift-P"
          "fullscreen", "Ctrl-Enter"
          "gotoLine",   "Ctrl-G"
          "gotoLineL",  "Ctrl-L"
          "saveAll",    "Ctrl-Alt-S"
          "closeTab",   "Ctrl-W"
          "settings",   "Ctrl-,"

          Workspace:
          ----------

          'split vertically',   'Ctrl-Alt-v'
          'split horizontally', 'Ctrl-Alt-h'
          'merge splitview',    'Ctrl-Alt-m'
          'create new file',    'Ctrl-Alt-n'
          'collapse sidebar',   'Ctrl-Alt-c'
          'expand sidebar',     'Ctrl-Alt-e'
          'go to left tab',     'Ctrl-Alt-['
          'go to right tab',    'Ctrl-Alt-]'
          'go to tab number',   'Ctrl-Alt-1'
          'go to tab number',   'Ctrl-Alt-2'
          'go to tab number',   'Ctrl-Alt-3'
          'go to tab number',   'Ctrl-Alt-4'
          'go to tab number',   'Ctrl-Alt-5'
          'go to tab number',   'Ctrl-Alt-6'
          'go to tab number',   'Ctrl-Alt-7'
          'go to tab number',   'Ctrl-Alt-8'
          'go to tab number',   'Ctrl-Alt-9'

          """

      @getEditor().setValue content, 1
      @ace.setReadOnly yes  if @getOptions().readOnly

  getEditor: ->
    return @aceView.ace.editor

  getValue: ->
    return  @getEditor().getSession().getValue()
