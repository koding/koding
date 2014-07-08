class IDE.EditorPane extends IDE.Pane

  shortcutsShown = no

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'editor-pane', options.cssClass
    options.paneType = 'editor'

    super options, data

    @on 'SaveRequested', @bound 'save'

    @createEditor()

  createEditor: ->
    {file, content} = @getOptions()

    unless file instanceof FSFile
      throw new TypeError 'File must be an instance of FSFile'

    unless content?
      throw new TypeError 'You must pass file content to IDE.EditorPane'

    aceOptions =
      delegate : @getDelegate()
      createFindAndReplaceView: no

    @addSubView @aceView = new AceView aceOptions, file

    {ace} = @aceView

    ace.once 'ace.ready', =>
      @getEditor().setValue content, 1
      ace.setReadOnly yes  if @getOptions().readOnly
      @emit 'EditorIsReady'

  save: ->
    {ace} = @aceView
    ace.emit 'ace.requests.save', ace.getContents()

  getEditor: ->
    return @aceView.ace.editor

  getValue: ->
    return  @getEditor().getSession().getValue()

  goToLine: (lineNumber) ->
    @aceView.ace.gotoLine lineNumber
