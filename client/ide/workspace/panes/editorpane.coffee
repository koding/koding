class EditorPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "editor-pane", options.cssClass

    super options, data

    @createEditor()

  createEditor: ->
    {file, content} = @getOptions()
    isLocalFile     = no

    unless file instanceof FSFile
      return new Error "File must be an instance of FSFile"

    unless content
      return new Error "You must pass file content to EditorPane"

    @ace = new AceView { delegate: this }, file
    @addSubView @ace
    @ace.once "ace.ready", =>
      @getEditor().setValue content, 1
      @ace.setReadOnly yes  if @getOptions().readOnly

  getEditor: ->
    return @ace.editor

  getValue: ->
    return  @getEditor().getSession().getValue()
