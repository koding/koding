class IDE.EditorPane extends IDE.Pane

  shortcutsShown = no

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'editor-pane', options.cssClass
    options.paneType = 'editor'

    super options, data

    @createEditor()

  createEditor: ->
    {file, content} = @getOptions()

    unless file instanceof FSFile
      throw new TypeError 'File must be an instance of FSFile'

    unless content?
      throw new TypeError 'You must pass file content to IDE.EditorPane'

    @addSubView @aceView = new AceView delegate: @getDelegate(), file
    {ace} = @aceView
    ace.once 'ace.ready', =>
      @getEditor().setValue content, 1
      ace.setReadOnly yes  if @getOptions().readOnly
      @emit 'EditorIsReady'

  getEditor: ->
    return @aceView.ace.editor

  getValue: ->
    return  @getEditor().getSession().getValue()
