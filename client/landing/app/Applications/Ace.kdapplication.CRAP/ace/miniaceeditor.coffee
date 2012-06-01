class MiniAceEditor extends Editor_CodeField
  constructor: ->
    super
    if @getOptions().autoGrow
      @getOptions().maxLinesNumber or= 15
      @getOptions().minLinesNumber or= 5
    
      @listenTo
        KDEventTypes: 'ready'
        listenedToInstance: @
        callback: =>
          @editorReady()
    
  viewAppended: ->
    file = 
      path      : @getOptions().path or '~~~/dummy-path/dummy.js'
      name      : @getOptions().name or 'dummy.js'
      contents  : @getOptions().defaultValue or ''

    unless @editor
      @getAce (ace)=>
        @editor = ace.edit "editor#{@getId()}"
        @editor.renderer.setHScrollBarAlwaysVisible no

        @_ready = yes
        @addSyntaxSelector()
        @openFile {file, loadContent: yes, afterOpen: @getOptions().afterOpen}
        @handleEvent type: 'ready'
    else
      @openFile {file, loadContent: yes, afterOpen: @getOptions().afterOpen}
  
  editorReady: ->
    @contentChanged()
    @refreshEditorView()
  
  refreshEditorView:->
    lines       = @editor.selection.doc.$lines

    if lines.length > @getOptions().maxLinesNumber
      linesNumber = @getOptions().maxLinesNumber
    else if lines.length < @getOptions().minLinesNumber
      linesNumber = @getOptions().minLinesNumber
    else
      linesNumber = lines.length
    @setHeightByLinesNumber linesNumber

      
  setHeightByLinesNumber: (linesNumber) ->
    lineHeight  = @editor.renderer.lineHeight
    container   = @editor.container
    height = linesNumber * lineHeight
    @setHeight height = linesNumber * lineHeight
    @editor.resize()
    @emit 'sizes.height.change', {height, lineHeight, linesNumber}
      
  loadAce:(cb)=>
    # console.log 'init application called'
    notification = no
    timeout = setTimeout ->
      notification = new KDNotificationView
        title   : "Still loading editor widget..."
        type    : 'tray'
        duration: 0
    , 2000

    require ['ace/ace'],(text, ace)=>
      clearTimeout timeout
      if notification
        notification.destroy()
        
      cb?()

  addSyntaxSelector: ->
    @addSubView @bottomBar  = new EditorBottomBarWithSyntaxOnly delegate : @

  setExtensionBasedPreferences: ->
    @setSyntaxBasedOnFileExtension()
    @setThemeBasedOnFileExtension()
    @setFontSizeBasedOnFileExtension()
    @setTabSizeBasedOnFileExtension()
    @setAdvacedSettingsBasedOnFileExtension()

  setDomElement:(cssClass)->
    @domElement = $ "<div class='kdview #{cssClass} editor-code-field'>
        <div id='editor#{@getId()}'  class='mini-code-wrapper'></div>
      </div>"

  notifySavedState: ->
    no
  
  _getOption: ->
    no

  _saveOption: ->
    no

  contentOpened: ->
    # if defaultValue = @getOptions().defaultValue
    #   @setValue defaultValue
