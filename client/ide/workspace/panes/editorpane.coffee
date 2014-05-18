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

    @aceView = new AceView delegate: @getDelegate(), file
    @aceView.ace.once "ace.ready", =>
      @getEditor().setValue content, 1
      @ace.setReadOnly yes  if @getOptions().readOnly

    @addSubView @aceView

  getEditor: ->
    return @aceView.ace.editor

  getValue: ->
    return  @getEditor().getSession().getValue()
