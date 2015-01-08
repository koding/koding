class Ace extends KDView

  constructor:(options, file)->

    super options, file

    @lastSavedContents     = ''
    {appStorageController} = KD.singletons
    @appStorage            = appStorageController.storage 'Ace', '1.0.1'

  setDomElement:(cssClass)->

    @domElement = $ "<figure class='kdview'><div id='editor#{@getId()}' class='code-wrapper'></div></figure>"

  viewAppended:->
    super
    @hide()
    @appStorage.fetchStorage (storage)=>

      requirejs ['ace/ace'], =>

        @keyHandlers = {}

        @fetchContents (err, contents)=>
          notification?.destroy()
          id = "editor#{@getId()}"
          return  unless document.getElementById id
          @editor = ace.edit id
          @prepareEditor()
          if contents
            @setContents contents
            @lastSavedContents = contents

          @editor.on 'change', =>
            @emit 'FileContentChanged'  unless @suppressListeners
            @emit 'FileContentRestored'  unless @isCurrentContentChanged()

          @editor.gotoLine 0
          
          # remove cmd+L binding. we have already defined cmd+g for this purpose
          @editor.commands.removeCommand 'gotoline'
          
          # we are using ctrl+alt+s for 'Save All' action
          @editor.commands.removeCommand 'sortlines'

          @focus()
          @show()

          @utils.defer => @emit 'ace.ready'

          KD.mixpanel 'Open Ace, success'

        @once 'ace.ready', =>
          LineWidgets = ace.require('ace/line_widgets').LineWidgets
          @Range      = ace.require('ace/range').Range
          @Anchor     = ace.require('ace/anchor').Anchor

          @lineWidgetManager = new LineWidgets @editor.session
          @lineWidgetManager.attach @editor


  setContent: (content, emitFileContentChangedEvent = yes) ->
    @suppressListeners = yes  unless emitFileContentChangedEvent

    @editor.setValue content, -1

    @suppressListeners = no   unless emitFileContentChangedEvent


  prepareEditor:->

    @setTheme()
    @setSyntax()
    @setEditorListeners()
    @appStorage.fetchStorage (storage)=>
      @setUseSoftTabs         @appStorage.getValue('useSoftTabs')         ? yes    ,no
      @setShowGutter          @appStorage.getValue('showGutter')          ? yes    ,no
      @setUseWordWrap         @appStorage.getValue('useWordWrap')         ? no     ,no
      @setShowPrintMargin     @appStorage.getValue('showPrintMargin')     ? no     ,no
      @setHighlightActiveLine @appStorage.getValue('highlightActiveLine') ? yes    ,no
      @setShowInvisibles      @appStorage.getValue('showInvisibles')      ? no     ,no
      @setFontSize            @appStorage.getValue('fontSize')            ? 12     ,no
      @setTabSize             @appStorage.getValue('tabSize')             ? 4      ,no
      @setKeyboardHandler     @appStorage.getValue('keyboardHandler')     ? 'default'
      @setScrollPastEnd       @appStorage.getValue('scrollPastEnd')       ? yes
      @setOpenRecentFiles     @appStorage.getValue('openRecentFiles')     ? yes

    requirejs ['ace/ext-language_tools'], =>
      @editor.setOptions
        enableBasicAutocompletion: yes
        enableSnippets: yes

  saveStarted:->
    @lastContentsSentForSave = @getContents()

  saveFinished:(err, res)->
    unless err
      @lastSavedContents = @lastContentsSentForSave
      @emit 'FileContentRestored'
      # unless @askedForSave
        # log "this file has changed, put a modal and block editing @fatihacet!"
        # fatihacet - this case works buggy.
      @askedForSave = no
    else if err?.message?.indexOf? 'permission denied' > -1
      @notify "You don't have enough permission to save!", 'error'

  saveAsFinished:->
    @emit 'FileContentRestored'
    @emit 'FileHasBeenSavedAs', @getData()

  setEditorListeners:->

    @editor.getSession().selection.on 'changeCursor', (cursor) =>
      return if @suppressListeners
      @emit 'ace.change.cursor', @editor.getSession().getSelection().getCursor()

    @editor.commands.on 'afterExec', (e) =>
      if e.command.name is 'insertstring' and /^[\w.]$/.test e.args
        @editor.completer and @editor.completer.autoInsert = off
        @editor.execCommand 'startAutocomplete'

    {enableShortcuts, createFindAndReplaceView} = @getOptions()

    if enableShortcuts
      @addKeyCombo 'save',       'Ctrl-S',           @bound 'requestSave'
      @addKeyCombo "saveAs",     "Ctrl-Shift-S",     @bound 'requestSaveAs'
      @addKeyCombo 'fullscreen', 'Ctrl-Enter', =>    @getDelegate().toggleFullscreen()
      @addKeyCombo 'gotoLine',   'Ctrl-G',           @bound 'showGotoLine'
      @addKeyCombo 'settings',   'Ctrl-,',           noop # override default ace settings view

      if createFindAndReplaceView
        @addKeyCombo 'find',    'Ctrl-F', =>        @showFindReplaceView no
        @addKeyCombo 'replace', 'Ctrl-Shift-F', =>  @showFindReplaceView yes
      else
        @addKeyCombo 'find',    'Ctrl-F', =>        @emit 'FindAndReplaceViewRequested', no
        @addKeyCombo 'replace', 'Ctrl-Shift-F', =>  @emit 'FindAndReplaceViewRequested', yes

      # these features are broken with IDE, should reimplement again
      # @addKeyCombo "preview",    "Ctrl-Shift-P", =>  @getDelegate().preview()
      # @addKeyCombo "closeTab",   "Ctrl-W", "Ctrl-W", @bound "closeTab"

  showFindReplaceView: (openReplaceView) ->
    {findAndReplaceView} = @getDelegate()
    selectedText         = @editor.session.getTextRange @editor.getSelectionRange()
    findAndReplaceView.setViewHeight openReplaceView
    findAndReplaceView.setTextIntoFindInput selectedText
    findAndReplaceView.on 'FindAndReplaceViewClosed', => @focus()

  addKeyCombo: (name, winKey, macKey, callback) ->
    if typeof macKey is 'function'
      callback = macKey
      macKey   = winKey.replace 'Ctrl', 'Command'
      macKey   = macKey.replace 'Alt', 'Option'
    @editor.commands.addCommand
      name    : name
      bindKey :
        win   : winKey
        mac   : macKey
      exec    : => callback?()

  isContentChanged: -> @contentChanged
  isCurrentContentChanged:-> @getContents() isnt @lastSavedContents

  closeTab: ->
    aceView   = @getDelegate()
    {tabView} = aceView.getDelegate()
    tabView.removePane_ tabView.getActivePane()

  ###
  FS REQUESTS
  ###

  requestSave:->
    contents = @getContents()
    unless contents is '' or @isContentChanged()
      if @getDelegate().parent.active
        @notify 'Nothing to save!'
      return
    file = @getData()
    {localSync} = KD.singletons
    # update the localStorage each time user requested save.
    if KD.remote.isConnected()
      @askedForSave = yes
      @emit 'ace.requests.save', contents
      # if file is saved, remove it from localStorage
      localSync.removeFromSaveArray file
    else
      # add to list of files that need to be synced.
      localSync.updateFileContentOnLocalStorage file, contents
      localSync.addToSaveArray file
      @prepareSyncListeners()

  prepareSyncListeners: ->
    {localSync} = KD.singletons

    localSync.on 'LocalContentSynced', (file) =>
      @notify 'File synced to remote...', null, null, 5000

    localSync.on 'LocalContentCouldntSynced', (file) =>
      @notify 'File coudn\'t be synced to remote please try again...', null, null, 5000

  requestSaveAs: ->
    @emit 'ace.requests.saveAs', @getContents()

  fetchContents:(callback)->
    file = @getData()
    unless /localfile:/.test file.path
      file.fetchContents callback
      # {vmName, path} = file
      # FSHelper.getInfo FSHelper.plainPath(path), vmName, (err, info)=>
      #   return if err or not info
      #   @emit 'FileIsReadOnly'  unless info.writable
    else
      callback null, file.contents or ''

  ###
  GETTERS
  ###

  getContents:-> @editor.getSession().getValue()

  getTheme:-> @editor.getTheme().replace 'ace/theme/', ''

  getSyntax:-> @syntaxMode

  getUseSoftTabs:->
    @appStorage.getValue('useSoftTabs') ? @editor.getSession().getUseSoftTabs()

  getShowGutter:->
    @appStorage.getValue('showGutter') ? @editor.renderer.getShowGutter()

  getShowPrintMargin:->
    @appStorage.getValue('showPrintMargin') ? @editor.getShowPrintMargin()

  getHighlightActiveLine:->
    @appStorage.getValue('highlightActiveLine') ? @editor.getHighlightActiveLine()

  getShowInvisibles:->
    @appStorage.getValue('showInvisibles') ? @editor.getShowInvisibles()

  getFontSize:->
    @appStorage.getValue('fontSize') ? parseInt @$("#editor#{@getId()}").css('font-size') ? 12, 10

  getTabSize:->
    @appStorage.getValue('tabSize') ? @editor.getSession().getTabSize()

  getUseWordWrap:->
    @appStorage.getValue('useWordWrap') ? @editor.getSession().getUseWrapMode()

  getKeyboardHandler: ->
    @appStorage.getValue('keyboardHandler') ? 'default'

  getScrollPastEnd: ->
    @appStorage.getValue('scrollPastEnd') ? yes

  getOpenRecentFiles:->
    @appStorage.getValue('openRecentFiles') ? yes

  getSettings:->
    theme               : @getTheme()
    syntax              : @getSyntax()
    useSoftTabs         : @getUseSoftTabs()
    showGutter          : @getShowGutter()
    useWordWrap         : @getUseWordWrap()
    showPrintMargin     : @getShowPrintMargin()
    highlightActiveLine : @getHighlightActiveLine()
    showInvisibles      : @getShowInvisibles()
    fontSize            : @getFontSize()
    tabSize             : @getTabSize()
    keyboardHandler     : @getKeyboardHandler()
    scrollPastEnd       : @getScrollPastEnd()
    openRecentFiles     : @getOpenRecentFiles()

  ###
  SETTERS
  ###

  setContents:(contents)-> @editor.getSession().setValue contents

  setSyntax:(mode)->

    file = @getData()
    mode or= file.syntax

    unless mode
      ext  = FSHelper.getFileExtension file.path
      for own name, [language, extensions] of __aceSettings.syntaxAssociations
        if ///^(?:#{extensions})$///i.test ext
          mode = name

      syntaxChoice = @appStorage.getValue "syntax_#{ext}"
      mode = syntaxChoice or mode or 'text'

    requirejs ["ace/mode-#{mode}"], =>
      {Mode} = ace.require "ace/mode/#{mode}"
      @editor.getSession().setMode new Mode
      @syntaxMode = mode

  setTheme:(themeName, save = yes)->
    themeName or= @appStorage.getValue('theme') or 'base16'
    requirejs ["ace/theme-#{themeName}"], =>
      callback = ace.require "ace/theme/#{themeName}"
      @editor.setTheme "ace/theme/#{themeName}"
      return  unless save
      @appStorage.setValue 'theme', themeName, =>
        callback

  setUseSoftTabs:(value, save = yes)->

    @editor.getSession().setUseSoftTabs value
    return  unless save
    @appStorage.setValue 'useSoftTabs', value

  setShowGutter:(value, save = yes)->

    @editor.renderer.setShowGutter value
    return  unless save
    @appStorage.setValue 'showGutter', value

  setShowPrintMargin:(value, save = yes)->

    @editor.setShowPrintMargin value
    return  unless save
    @appStorage.setValue 'showPrintMargin', value

  setHighlightActiveLine:(value, save = yes)->

    @editor.setHighlightActiveLine value
    return  unless save
    @appStorage.setValue 'highlightActiveLine', value

  # setHighlightSelectedWord:(value)-> @editor.setHighlightActiveLine value

  setShowInvisibles:(value, save = yes)->

    @editor.setShowInvisibles value
    return  unless save
    @appStorage.setValue 'showInvisibles', value

  setKeyboardHandler: (name = 'default') ->
    done = (handler) =>
      @editor.setKeyboardHandler handler
      @appStorage.setValue 'keyboardHandler', name

    next = (path) =>
      binding = ace.require path
      @keyHandlers[name] = binding.handler
      done binding.handler

    if name is 'default'
      done null
    else
      path = "ace/keyboard/#{name}"
      unless name of @keyHandlers
        requirejs [path.replace('board/', 'binding-')], ->
          next path
      else
        done @keyHandlers[name]

  setScrollPastEnd: (value = yes) ->
    @editor.setOption 'scrollPastEnd', value
    @appStorage.setValue 'scrollPastEnd', value

  setFontSize:(value, save = yes)->
    return if value is KD.config.oldFontSize

    style           = document.createElement 'style'
    style.id        = 'ace-font-size'
    style.innerHTML = ".ace_editor { font-size: #{value}px }"

    oldStyleTag     = document.getElementById style.id
    oldStyleTag.parentNode.removeChild oldStyleTag if oldStyleTag

    document.head.appendChild style
    KD.config.oldFontSize = value

    return  unless save
    @appStorage.setValue 'fontSize', value

  setTabSize:(value, save = yes)->

    @editor.getSession().setTabSize +value
    return  unless save
    @appStorage.setValue 'tabSize', value

  setUseWordWrap:(value, save = yes)->

    @editor.getSession().setUseWrapMode value
    return  unless save
    @appStorage.setValue 'useWordWrap', value

  setReadOnly:(value)-> @editor.setReadOnly value

  setOpenRecentFiles:(value, save = yes)->
    @appStorage.setValue 'openRecentFiles', value

  gotoLine: (lineNumber) ->
    @editor.gotoLine lineNumber

  focus: -> @editor?.focus()

  ###
  HELPERS
  ###

  notification = null
  notify:(msg, style, details, duration)->

    notification.destroy() if notification

    style or= 'error' if details

    notification = new KDNotificationView
      title     : msg or 'Something went wrong'
      type      : 'mini'
      cssClass  : "#{style}"
      duration  : duration or if details then 5000 else 2500
      details   : details
      click     : ->
        if notification.getOptions().details
          details = new KDNotificationView
            title     : 'Error details'
            content   : notification.getOptions().details
            type      : 'growl'
            duration  : 0
            click     : -> details.destroy()

          KD.getSingleton('windowController').addLayer details

          details.on 'ReceivedClickElsewhere', =>
            details.destroy()

  #obsolete: Now we are using IDE saveAllFiles method
  saveAllFiles: ->
    aceApp = KD.singletons.appManager.get 'Ace'
    return unless aceApp

    {aceViews} = aceApp.getView()

    for path, aceView of aceViews when aceView.data.parentPath isnt 'localfile:'
      aceView.ace.requestSave()
      aceView.ace.once 'FileContentRestored', @bound 'removeModifiedFromTab'

  removeModifiedFromTab: ->
    aceView      = @parent
    {name}       = aceView.ace.data
    {handles}    = aceView.delegate.tabView
    targetHandle = null

    for handle in handles when handle.getOptions().title is name
      targetHandle = handle
      targetHandle.setClass 'saved'

      KD.utils.wait 500, ->
        targetHandle.unsetClass 'modified'
        targetHandle.unsetClass 'saved'

  showGotoLine: ->
    unless @gotoLineModal
      @gotoLineModal = new KDModalViewWithForms
        cssClass                : 'goto'
        width                   : 180
        height                  : 'auto'
        overlay                 : yes
        tabs                    :
          forms                 :
            Go                  :
              callback          : (form) =>
                lineNumber = parseInt form.line, 10
                @gotoLine lineNumber if lineNumber > 0
                @gotoLineModal.destroy()
              fields            :
                Line            :
                  type          : 'text'
                  name          : 'line'
                  placeholder   : 'Goto line'
                  nextElement   :
                    Go              :
                      itemClass     : KDButtonView
                      title         : 'Go'
                      style         : 'solid green'
                      type          : 'submit'

      @gotoLineModal.on 'KDModalViewDestroyed', =>
        @gotoLineModal = null
        @focus()

      @gotoLineModal.modalTabs.forms.Go.focusFirstElement()
