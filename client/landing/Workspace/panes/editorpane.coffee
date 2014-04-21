class EditorPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "editor-pane", options.cssClass

    super options, data

    {@files} = @getOptions()

    if Array.isArray @files then @createEditorTabs() else @createSingleEditor()

  createEditorInstance: (file, content) ->
    ace = new Ace
      delegate        : this
      enableShortcuts : no
    , file

    if content
      ace.once "ace.ready", ->
        ace.editor.setValue content

    return ace

  createSingleEditor: ->
    path      = @files or "localfile:/Untitled.txt"
    file      = FSHelper.createFileFromPath path
    {content} = @getOptions()
    @ace      = @createEditorInstance file, content

  createEditorTabs: ->
    @editors              = {}
    @tabHandleContainer   = new ApplicationTabHandleHolder
      delegate            : this
      addPlusHandle       : no

    @tabView              = new ApplicationTabView
      delegate            : this
      tabHandleContainer  : @tabHandleContainer
      detachPanes         : no

    @files.forEach (options) =>
      {name, path, content} = options
      file                  = FSHelper.createFileFromPath path
      pane                  = new KDTabPaneView
        name                : file.name or "Untitled.txt"
        closable            : no

      editor = @createEditorInstance file, content
      pane.addSubView editor
      @tabView.addPane pane
      @editors[name] = editor  if name

  # use this for single editor
  getValue: ->
    return  @ace.editor.getSession().getValue()

  # use this for multiple editor tabs
  getValues: ->
    data = {}
    for name, editorInstance of @editors
      data[name] = editorInstance.editor.getValue()

    return data

  pistachio: ->
    single   = "{{> @ace}}"
    multiple = "{{> @tabHandleContainer}} {{> @tabView}}"
    template = if Array.isArray @files then multiple else single
    return  """
      {{> @header}}
      #{template}
    """
