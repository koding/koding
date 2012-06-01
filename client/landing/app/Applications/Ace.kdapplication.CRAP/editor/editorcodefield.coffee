class Editor_CodeField extends KDView
  constructor: ->
    super
    @file       = @getOptions().file
    @fileItem   = @getOptions().fileItem

    # @listenTo
    #   KDEventTypes:
    #     eventType: 'RequestFileHasChanged'
    #   callback: (pubInst, event) =>
    #     log 'req++++++'
    #     # log 'pub inst', pubInst, event
    #     publishedFile = event.file
    #     newContent    = event.newContent
    #     iniciatedBy   = event.iniciatedBy #we have to now initiator
    #     
    #     return unless publishedFile
    #     if @ isnt iniciatedBy
    #       if @file is publishedFile and not @file.new
    #         if newContent isnt @getValue()
    #           @setValueWithoutEventPropagations newContent

  setDomElement:(cssClass)->
    @domElement = $ "<div class='kdview #{cssClass} editor-code-field'>
        <div id='editor#{@getId()}'  class='code-wrapper'></div>
      </div>"

  doResize: (sizes) ->
    @editor.resize() if @editor

  getAce:(callback)->
    # ace = window.__ace_shadowed__
    require ['ace/ace'], (ace)->
      # window.ace.require = window.require
      # ace = window.ace
      callback? ace

  getEditor: ->
    @getDelegate()

  getPageEditor: ->
    @getEditor().getPageEditor()

  getEditorTabPane: ->
    @getEditor().getDelegate()

  getActiveEditorTabPane: ->
    @getPageEditor().getActiveEditorView().getDelegate()


  getActiveCodeField: ->
    # @getOptions().splittable.getActiveCodeField()
    # console.log 'getActiveCodeField:::i am not sure but looks like we are now always in scope of active code field'
    @

  _getOption: (name) ->
    extensionName = @getEditor().getFileExtension @file
    # log extensionName + '.' + name
    option = @getAceView().storage.bucket[extensionName + '.' + name]
    option
    # option = {}

  _saveOption: (name, value) ->
    if value is false or typeof value is "undefined"
      value = 0
    else if value is true
      value = 1
    extension         = @getEditor().getFileExtension @file
    storage           = @getAceView().storage
    storage.setOption extension + '.' + name, value

  setCursor: ({row, column}) ->
    # console.log @editor, '<<<'
    @editor.moveCursorTo row, column

  setExtensionBasedPreferences: ->
    @setSyntaxBasedOnFileExtension()
    @_setDefaultSearchOptions()
    @setThemeBasedOnFileExtension()
    @setFontSizeBasedOnFileExtension()
    @setTabSizeBasedOnFileExtension()
    @setAdvacedSettingsBasedOnFileExtension()

  setAdvacedSettingsBasedOnFileExtension: ->
    showGutter = @_getOption 'showGutter'
    @_setShowGutter !!showGutter if showGutter?
    
    printMargin = @_getOption('showPrintMargin')
    @_setShowPringMargin !!printMargin

    useSoftTabs = @_getOption 'useSoftTabs'
    @_setUseSoftTabs !!useSoftTabs

    activeLine = @_getOption 'highlightActiveLine'
    @_setHighlightActiveLine !!activeLine
    
    # softTabs = @_getOption 'softTabs'
    # @_setSoftTabs !!softTabs

    wrapMode = @_getOption 'wrapMode'
    unless wrapMode
      wrapMode = 'off'
    @_setUseWrapMode wrapMode
    
    word = @_getOption 'highlightActiveWord'
    @_setHightlightSelectedWord !!word
    
    showInvisibles = @_getOption 'showInvisibles'
    @_setShowInvisibles !!showInvisibles

  _setHightlightSelectedWord: (shouldHighlight) ->
    @editor.setHighlightSelectedWord shouldHighlight

  setHighlightSelectedWord: (shouldHighlight) ->
    @_setHightlightSelectedWord shouldHighlight
    @_saveOption 'highlightActiveWord', shouldHighlight

  getHighlightSelectedWord: ->
    @editor.getHighlightSelectedWord()

  getUseWrapMode: ->
    if not @editor.getSession().getUseWrapMode()
      return 'off'
    else
      limit = @editor.getSession().getWrapLimitRange().min
      if limit is null
        return 'free'
      else
        return limit

  _setUseWrapMode: (value) ->
    session   = @editor.getSession()
    renderer  = @editor.renderer
    # log 'setting wrap mode', value, typeof value
    switch value
      when 'off'
        session.setUseWrapMode wrapMode = no
        renderer.setPrintMarginColumn margin = 80
      when '40'
        session.setUseWrapMode wrapMode = yes
        session.setWrapLimitRange 40, limit = 40
        renderer.setPrintMarginColumn margin = 40
      when '80'
        session.setUseWrapMode wrapMode = yes
        session.setWrapLimitRange 80, limit = 80
        renderer.setPrintMarginColumn margin = 80
      when 'free'
        session.setUseWrapMode wrapMode = yes
        session.setWrapLimitRange null, limit = null
        renderer.setPrintMarginColumn margin = 80

  setUseWrapMode: (value) ->

    @_setUseWrapMode value        
    @_saveOption 'wrapMode', value

  getUseSoftTabs: ->
    @editor.getSession().getUseSoftTabs()

  getShowGutter: ->
    @editor.renderer.getShowGutter()

  _setShowGutter: (show) ->
    @editor.renderer.setShowGutter(show)
    if show
      @setClass 'with-line-numbers'
    else
      @unsetClass 'with-line-numbers'

  setShowGutter: (show) ->
    @_setShowGutter show
    @_saveOption 'showGutter', show

  _setShowPringMargin: (show) ->
    @editor.renderer.setShowPrintMargin show

  setShowPrintMargin: (show) ->
    @_setShowPringMargin show
    @_saveOption 'showPrintMargin', show

  getShowPrintMargin: ->
    @editor.renderer.getShowPrintMargin()

  _setUseSoftTabs: (use) ->
    @editor.getSession().setUseSoftTabs use

  setUseSoftTabs: (use) ->
    @_setUseSoftTabs use
    @_saveOption 'useSoftTabs', use

  _setHighlightActiveLine: (highlight) ->
    @editor.setHighlightActiveLine highlight

  setHighlightActiveLine: (highlight = yes) ->
    @_setHighlightActiveLine highlight
    @_saveOption 'highlightActiveLine', highlight

  getHighlightActiveLine: ->
    @editor.getHighlightActiveLine()

  _setSoftTabs: (softTabs = yes) ->
    @editor.getSession().setUseSoftTabs softTabs

  setSoftTabs: (softTabs = yes) ->
    @_setSoftTabs softTabs
    @_saveOption 'softTabs', softTabs

  setTabSize: (size) ->
    @_tabSize = size
    @editor.getSession().setTabSize parseInt size

  getTabSize: ->
    @_tabSize

  saveTabSizeForExtension: (size) ->
    @_saveOption 'tabSize', size

  saveSyntaxForExtension: (syntaxName) ->
    @_saveOption 'syntax', syntaxName

  setTabSizeBasedOnFileExtension: ->
    size = sizeOption = @_getOption 'tabSize'
    if sizeOption
      @setTabSize sizeOption
    else
      @setTabSize size = 2

    @_editorAsksToSetTabSize()
    # @handleEvent type: 'EditorAsksToSetTabSize', size: size

  saveFontSizeForExtension: (size) ->
    @_saveOption 'fontSize', size

  saveThemeForExtension: (theme) ->
    @_saveOption 'theme', theme

  setFontSizeBasedOnFileExtension: ->
    size = sizeOption = @_getOption 'fontSize'
    #since getting options is broken
    if sizeOption
      @setFontSize sizeOption
    else
      @setFontSize size = 12

    @_editorAsksToSetFontSize()
    # @handleEvent type: 'EditorAsksToSetFontSize', size: size

  setFontSize: (size) ->
    @_fontSize = size
    $(@editor.container).css
      fontSize: size + 'px'

  getFontSize: ->
    @_fontSize

  setThemeBasedOnFileExtension: ->
    theme = themeFromOptions = @_getOption 'theme'
    if themeFromOptions and 'string' is typeof theme
      @setTheme themeFromOptions
    else
      @setTheme theme = 'merbivore'

    @_editorAsksToSetTheme theme 
    # @handleEvent type: 'EditorAsksToSetTheme', theme: theme

  getTheme: ->
    @_activeTheme

  setTheme: (themeName) ->
    @_activeTheme = themeName
    @getAce (ace)=>

      notification = no
      timeout = setTimeout ->
        notification = new KDNotificationView
          title   : "Still loading theme #{themeName}..."
          type    : 'tray'
          duration: 0
      , 1000

      require ["ace/theme/#{themeName}"], (callback) =>
        clearTimeout timeout
        @editor.setTheme 'ace/theme/' + themeName
        if notification
          notification.destroy()

  getFileExtension: (file) ->
    fileName = ''
    if file.path
      fileName = file.path
    else
      fileName = file.title

    extension = __utils.getFileExtension fileName

  setSyntaxBasedOnFileExtension: ->
    syntaxFromOptions       = @_getOption 'syntax'
    if syntaxFromOptions and 'string' is typeof syntaxFromOptions #setting syntax from options
      @setSyntax syntaxFromOptions, =>
        @_editorAsksToSetSyntax syntax: syntaxFromOptions
      return

    accociations          = __aceData.syntaxExtensionAssociations
    extensionName         = @getFileExtension @file
    for own syntax, extensions of accociations
      if extensionName in extensions
        @setSyntax syntax, =>
          @_editorAsksToSetSyntax syntax
        return

    # log 'couldnt detect syntax, will set to javascript'
    @setSyntax 'javascript', =>
      @_editorAsksToSetSyntax 'javascript'

  getActiveSyntaxName: ->
    @_activeSyntaxName

  setSyntax: (syntaxName, cb) ->
    @getAce (ace)=>
      @_activeSyntaxName = syntaxName
      notification = no
      timeout = setTimeout ->
        notification = new KDNotificationView
          title   : "Still loading syntax #{syntaxName}..."
          type    : 'tray'
          duration: 0
      , 1000


      require ["ace/mode/#{syntaxName}"], () =>
        clearTimeout timeout
        # FIXME: temp comment-out since it's broke
      
        syntax  = require('ace/mode/' + syntaxName).Mode
        @editor.getSession().setMode new syntax()
        cb?()
        if notification
          notification.destroy()

  getFileContents:(callback)->
    @getPageEditor().getFinder().getFileContents @file, (file) ->
      # console.log 'i got content of the file'
      callback file

  viewAppended: ->
    unless @editor?
      # console.log 'appending bottom bar'
      # @addSubView @topBar     = new Editor_TopBar delegate : @
      @addSubView @bottomBar  = new Editor_BottomBar delegate : @
      @getAce (ace)=>
        @editor = ace.edit "editor#{@getId()}"
      
        # @setAceListeners()
        @dropDefaultShortcuts()
        @setEditorListeners @editor

        @_ready = yes
        @handleEvent type: 'ready'

  openFile: (options) ->
    if @_ready
      @_openFile options
    else
      @listenTo
        KDEventTypes: 'ready'
        listenedToInstance: @
        callback: =>
          # console.log 'editor ready>>>>>>'
          @_openFile options
          
  setFileListeners: (file) ->
    return unless file instanceof File
    
    fileHasChangedCallback = =>
      # log 'changed'
      file.getContents (content) =>
        return if content is @getValue()
        position = @editor.getCursorPosition()
        @setValueWithoutEventPropagations content
        @setCursor position
    
    eventsMap = 
      'change'    : fileHasChangedCallback
      
    for evetName, callback of eventsMap
      file.on evetName, callback
      
    unsubscriber = =>
      # log 'unsubscribing'
      for evetName, callback of eventsMap
        file.unsubscribe evetName, callback
        
      @unsubscribe 'file.unsubscribe', unsubscriber
      
    @on 'file.unsubscribe', unsubscriber

          

  _openFile: (options) ->
    {file, fileItem, loadContent, afterOpen} = options
    if @file
      @emit 'file.unsubscribe'
    
    @file     = file
    @fileItem = fileItem

    @getAce (ace)=>
      # unless @editor
      #   @editor = ace.edit "editor#{@getId()}"
      #   @setEditorListeners @editor
      
      @setFileListeners file

      @setExtensionBasedPreferences()


      # @editor.getSession().setValue "Loading..."

      @_propagateOnChange = yes

      if loadContent
        contents = file.contents
        @setValue contents or ""
        @editor.gotoLine 0
        @editor.getSession().on 'change', (args)=>
          if @_propagateOnChange
            @contentChanged args
        @contentOpened()
        afterOpen?()
      else
        @editor.getSession().setValue ""
        @editor.getSession().on 'change', (args)=>
          if @_propagateOnChange
            @contentChanged args
        @contentOpened()
        afterOpen?()


  _setShowInvisibles: (show) ->
    @editor.setShowInvisibles show

  setShowInvisibles: (show) ->
    @_setShowInvisibles show
    @_saveOption 'showInvisibles', show

  getShowInvisibles: ->
    @editor.getShowInvisibles()

  getLastSearchOptions: ->
    @editor.getLastSearchOptions()

  _setDefaultSearchOptions: ->
    storage = @getAceView().storage
    defaults =
      backwards     : storage.bucket['search.backwards'] or no
      wrap          : !!storage.bucket['search.wrap']
      caseSensitive : !!storage.bucket['search.caseSensitive']
      wholeWord     : !!storage.bucket['search.wholeWord']
      regExp        : !!storage.bucket['search.regExp']

    @_setSearchOptions defaults

  _setSearchOptions: (options) ->
    @editor.$search.set options

  setSearchOptions: (options) ->
    for name, value of options
      @getAceView().storage.setOption "search.#{name}", value
    
    lastOptions = @getLastSearchOptions()
    setOptions = $.extend lastOptions, options
    @_setSearchOptions setOptions

  contentOpened:()->
    @focus()
    @isSaved = yes
    # @tabPane.notifySavedState @isSaved
    # @notifySavedState @isSaved
    @initialContent = @editor.getSession().getValue()

    @doResize()


  contentChanged:(args)->
    @isSaved = @editor.getSession().getValue() is @initialContent
    @notifySavedState @isSaved
    @handleEvent type: 'AceEditorContentChanged'

  focus: ->
    $(@editor.container).mousedown()
    @editor.focus()

    (@getSingleton "windowController").setKeyView null


  _onFocus: ->
    # @_editorChangeCursorPosition()
    # @_editorAsksToSetSyntax()
    # @_editorAsksToSetTheme()
    # @_editorAsksToSetFontSize()
    # @_editorAsksToSetTabSize()

    #editor got focus, lets notify parents
    @handleEvent type: 'EditorCodeViewInFocus'

    #notifying saved state, this will also reflect tab title
    # @notifySavedState @isSaved
    
  click: ->
    @editor.textInput.focus()

  onFocus: ->
    #hack, ace triggers too much onfocus events
    clearTimeout @__onFocusTimer
    @__onFocusTimer = setTimeout =>
      @_onFocus()
    , 0

  getValue: ->
    @editor.getSession().getValue()

  setValue: (value) ->
    @editor.getSession().setValue value

  setValueWithoutEventPropagations: (value) ->
    @_propagateOnChange = no
    @editor.getSession().setValue value
    @_propagateOnChange = yes

  _editorChangeCursorPosition: (editor = @editor) ->
    pos = editor.getCursorPosition()
    @handleEvent type: 'EditorChangeCursorPosition', row: pos.row, column: pos.column

  _editorAsksToSetSyntax: () ->
    if @_activeSyntaxName
      @handleEvent type: 'EditorAsksToSetSyntax', syntax: @_activeSyntaxName

  _editorAsksToSetTheme: ->
    @handleEvent type: 'EditorAsksToSetTheme', theme: @_activeTheme

  _editorAsksToSetFontSize: ->
    @handleEvent type: 'EditorAsksToSetFontSize', size: @_fontSize

  _editorAsksToSetTabSize: ->
    @handleEvent type: 'EditorAsksToSetTabSize', size: @_tabSize

  setEditorListeners: (editor) ->
    editor.on 'focus', =>
      @onFocus()

    editor.getSession().selection.on 'changeCursor', (a, b, c) =>
      @_editorChangeCursorPosition editor

    @listenTo
      KDEventTypes: 'WindowChangeKeyView'
      callback: (pubInst, event) ->
        editor.blur()

    @listenTo
      KDEventTypes : ["RerenderAceSize"]
      listenedToInstance : @
      callback : ->
        # log ":::::::::::::::>>>>>>>>>>><<<<<<<<<<<<:::::::::::::::::::",@
        editor.renderer.onResize yes

  find:(pubInst,event)->
    options = @getLastSearchOptions()
    {search} = event
    if not search
      search = @_lastSearch
    else
      @_lastSearch = search
    if options.backwards
      @editor.findPrevious options
    else
      @editor.find search, options
      # @editor.find search,
      #   backwards     : options.backwards
      #   wrap          : options.wrap
      #   caseSensitive : options.caseSensitive
      #   wholeWord     : options.wholeWord
      #   regExp        : options.regExp
    setTimeout =>
      @editor.focus()
    , 150

  replace:(pubInst,event)->
    {search,replace,all} = event
    # @editor.find search
    unless all
      selected = @editor.getSession().doc.getTextRange(@editor.getSelectionRange())
      if selected.length
        @editor.insert replace
    else
      @editor.replaceAll replace

  isDroppable: ->
    yes

  dropAccept: (item) ->
    dropping = item.data('KDPasteboard')
    if dropping and $.isArray(dropping) and dropping.length is 1 and dropping[0].type is 'file'
      yes
    else
      no

  dropOver:(event,ui) =>
    ui.helper.addClass 'drop-is-acceptable'

  dropOut: (event, ui) =>
    ui.helper.removeClass 'drop-is-acceptable'

  jQueryDrop: (event, ui) ->
    dropping = ui.draggable.data('KDPasteboard')
    if dropping and $.isArray(dropping) and dropping.length is 1 and dropping[0].type is 'file'
      # console.log @getPageEditor(), '<<<<', @getAceView()
      @getAceView().openFileByDrop dropping[0], @
      # @getPageEditor().getOptions().controller.openFileByDrop @, dropping[0]
      # @openFile file: dropping[0], loadContent: yes
      
  dropDefaultShortcuts: ->
    if @_defaultShortcutsDropped
      return
      
    @_defaultShortcutsDropped = yes
    
    @editor.commands.removeCommand 'find'
    @editor.commands.removeCommand 'findnext'
    
  getAceView: ->
    @getDelegate().getDelegate()

  close: (callback) ->
    if @isSaved
      @_close()
      return callback? yes
    else
      @_close()
      callback? yes
  
  _close: ->
    @getOptions().splittable.removeEditor @
    
  destroy: ->
    @emit 'file.unsubscribe'
    super

  notifySavedState: (state) ->
    @file.setContents @getValue()

  tryToRun: ->
    switch @getActiveSyntaxName()
      when 'coffee'
        @_compile (error, source) =>
          if source
            @_runJs source
      when 'javascript'
        toRun = @editor.getSession().doc.getTextRange(@editor.getSelectionRange())
        unless toRun
          toRun = @editor.getSession().getValue()
        @_runJs toRun

  _runJs: (js) ->
    frame = new KDCustomHTMLView 
      tagName     : 'iframe'
      attributes  :
        src       : '/js/apps/ace/additional/js-runner.html'
    frame.$().load () =>
      runner = frame.$()[0].contentWindow.run
      runner js, (error, result) =>
        if error
          new KDModalView
            title: 'Execution error'
            content: 'Error type: ' + error.type + ' arguments:' + error.arguments.join(', ')
        frame.destroy()

    @addSubView frame

  tryToCompile: ->
    @_compile (error, result) =>
      if result
        new CompiledCodeWindow
          title: 'Compile result'
          code: result
          width: 700
          height: 400


  _compile: (callback) ->
    requirePath = 'ace/compilers/' + @getActiveSyntaxName()
    #lets try to load compiler
    if KD.requirePathExists requirePath
      KD.require requirePath,  =>

        toCompile = @editor.getSession().doc.getTextRange(@editor.getSelectionRange())
        unless toCompile
          toCompile = @editor.getSession().getValue()

        callData = __aceData.compilerCallNames[@getActiveSyntaxName()]
        if callData
          try
            compiledSource = window[callData.class][callData.method] toCompile, callData.options
          catch e
            compiledSource = e.message
          return callback null, compiledSource
        else
          return callback 'Call data doesnt exist'
    else
      # log 'There is no compiler for ' + @getActiveSyntaxName()
      return callback 'There is no compiler for ' + @getActiveSyntaxName()

  tryToAutocomplete: (options) ->
    {backward} = options

    cursor  = @editor.selection.getCursor()
    range   = @editor.session.getWordRange(cursor.row, cursor.column)

    if @_suggestIterationInitiated
      _range = @_suggestIterationInitiated.range
      if _range.start.column isnt range.start.column or _range.start.row isnt range.start.row
        @_suggestIterationInitiated = no

    if cursor.column > range.start.column
      range.end.column  = cursor.column
      if not @_suggestIterationInitiated
        @_suggestIterationInitiated = 
          range: range
          currentSuggest: -1

      word              = @editor.session.getTextRange(@_suggestIterationInitiated.range)
      suggestions       = @getSuggestionsFor word

      if backward
        @_suggestIterationInitiated.currentSuggest--
      else
        @_suggestIterationInitiated.currentSuggest++
      if not suggestions[@_suggestIterationInitiated.currentSuggest]
        if backward
          @_suggestIterationInitiated.currentSuggest = suggestions.length - 1
        else
          @_suggestIterationInitiated.currentSuggest = 0

      if suggestions[@_suggestIterationInitiated.currentSuggest]
        suggest = suggestions[@_suggestIterationInitiated.currentSuggest]
        # log 'word to suggest', suggest
        @editor.session.replace @editor.session.getWordRange(cursor.row, cursor.column), suggest

  getSuggestionsFor: (checkWord) ->
    # log 'check word', checkWord
    wholeText         = @editor.session.getValue()

    matcher           = /[A-Za-z_]+(?:['-][A-Za-z]+)?|\\d+(?:[,.]\\d+)?/ig
    words             = wholeText.match matcher
    unique            = []
    for word in words
      if word not in unique and word isnt checkWord and word.indexOf(checkWord) is 0
        unique.push word

    unique
