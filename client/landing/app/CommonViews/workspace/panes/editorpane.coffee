class EditorPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "editor-pane"

    super options, data

    @appStorage = new AppStorage "Ace", "1.0"

    @files = @getProperty "files"

    if Array.isArray @files then @createEditorTabs() else @createSingleEditor()

  createEditorInstance: (file) ->
    return new Ace
      delegate        : @
      enableShortcuts : no
    , file

  createSingleEditor: ->
    path = @files or "localfile:/Untitled.txt"
    file = FSHelper.createFileFromPath path
    @ace = @createEditorInstance file

  createEditorTabs: ->
    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate      : @
      addPlusHandle : no

    @tabView = new ApplicationTabView
      delegate           : @
      tabHandleContainer : @tabHandleContainer

    for fileOptions in @files
      file   = FSHelper.createFileFromPath fileOptions.path
      pane   = new KDTabPaneView
        name : file.name or "Untitled.txt"

      pane.addSubView @createEditorInstance file
      @tabView.addPane pane

  getValue: ->
    return  @ace.editor.getSession().getValue()

  pistachio: ->
    single   = "{{> @ace}}"
    multiple = "{{> @tabHandleContainer}} {{> @tabView}}"
    return  if Array.isArray @files then multiple else single