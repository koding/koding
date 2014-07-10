###
  todo:

    - fix setSoftWrap it goes back to off when you reopen the settings

###


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
      requirejs ['ace/ace'], (ace)=>
        @fetchContents (err, contents)=>
          notification?.destroy()
          id = "editor#{@getId()}"
          return  unless document.getElementById id
          @editor = ace.edit id
          @prepareEditor()
          @utils.defer => @emit 'ace.ready'
          if contents
            @setContents contents
            @lastSavedContents = contents
          @editor.on 'change', =>
            if @isCurrentContentChanged() then @emit 'FileContentChanged' else @emit 'FileContentSynced'
          @editor.gotoLine 0
          @focus()
          @show()

          KD.mixpanel 'Open Ace, success'

      requirejs ['ace/keyboard/vim'], (vimMode) =>
        @vimKeyboardHandler = vimMode.handler

      @emacsKeyboardHandler = 'ace/keyboard/emacs'

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
      @setSoftWrap            @appStorage.getValue('softWrap')            or 'off' ,no
      @setFontSize            @appStorage.getValue('fontSize')            ? 12     ,no
      @setTabSize             @appStorage.getValue('tabSize')             ? 4      ,no
      @setKeyboardHandler     @appStorage.getValue('keyboardHandler')     ? 'default'
      @setScrollPastEnd       @appStorage.getValue('scrollPastEnd')       ? yes
      @setOpenRecentFiles     @appStorage.getValue('openRecentFiles')     ? yes

    requirejs ['ace/ext/language_tools'], =>
      @editor.setOptions
        enableBasicAutocompletion: yes
        enableSnippets: yes

  saveStarted:->
    @lastContentsSentForSave = @getContents()

  saveFinished:(err, res)->
    unless err
      @notify 'Successfully saved!', 'success'
      @lastSavedContents = @lastContentsSentForSave
      @emit 'FileContentSynced'
      # unless @askedForSave
        # log "this file has changed, put a modal and block editing @fatihacet!"
        # fatihacet - this case works buggy.
      @askedForSave = no
    else if err?.message?.indexOf? 'permission denied' > -1
      @notify "You don't have enough permission to save!", 'error'

  saveAsFinished:->
    @emit 'FileContentSynced'
    @emit 'FileHasBeenSavedAs', @getData()

  setEditorListeners:->

    @editor.getSession().selection.on 'changeCursor', (cursor)=>
      @emit 'ace.change.cursor', @editor.getSession().getSelection().getCursor()

    {enableShortcuts, createFindAndReplaceView} = @getOptions()

    if enableShortcuts
      @addKeyCombo 'save',       'Ctrl-S',           @bound 'requestSave'
      @addKeyCombo 'fullscreen', 'Ctrl-Enter', =>    @getDelegate().toggleFullscreen()
      @addKeyCombo 'gotoLine',   'Ctrl-G',           @bound 'showGotoLine'
      @addKeyCombo 'gotoLineL',  'Ctrl-L',           @bound 'showGotoLine'
      @addKeyCombo 'saveAll',    'Ctrl-Alt-S',       @bound 'saveAllFiles'
      @addKeyCombo 'settings',   'Ctrl-,',           noop # override default ace settings view

      if createFindAndReplaceView
        @addKeyCombo 'find',    'Ctrl-F', =>        @showFindReplaceView no
        @addKeyCombo 'replace', 'Ctrl-Shift-F', =>  @showFindReplaceView yes
      else
        @addKeyCombo 'find',    'Ctrl-F', =>        @emit 'FindAndReplaceViewRequested', no
        @addKeyCombo 'replace', 'Ctrl-Shift-F', =>  @emit 'FindAndReplaceViewRequested', yes

      # these features are broken with IDE, should reimplement again
      # @addKeyCombo "saveAs",     "Ctrl-Shift-S",     @bound "requestSaveAs"
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

  requestSaveAs: (options) ->
    contents = @getContents()
    @emit 'ace.requests.saveAs', contents

  fetchContents:(callback)->
    file = @getData()
    unless /localfile:/.test file.path
      @notify 'Loading...', null, null, 10000
      file.fetchContents callback
      {vmName, path} = file
      FSHelper.getInfo FSHelper.plainPath(path), vmName, (err, info)=>
        return if err or not info
        @emit 'FileIsReadOnly'  unless info.writable
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

  getSoftWrap:->

    limit = @appStorage.getValue('softWrap') ? @editor.getSession().getWrapLimitRange().max
    if limit then limit
    else
      if @getUseWordWrap() then 'free' else 'off'

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
    softWrap            : @getSoftWrap()
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
      ext  = FSItem.getFileExtension file.path
      for own name, [language, extensions] of __aceSettings.syntaxAssociations
        if ///^(?:#{extensions})$///i.test ext
          mode = name

      syntaxChoice = @appStorage.getValue "syntax_#{ext}"
      mode = syntaxChoice or mode or 'text'

    requirejs ["ace/mode/#{mode}"], ({Mode})=>
      @editor.getSession().setMode new Mode
      @syntaxMode = mode

  setTheme:(themeName, save = yes)->
    themeName or= @appStorage.getValue('theme') or 'koding'
    requirejs ["ace/theme/#{themeName}"], (callback) =>
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

  setKeyboardHandler: (value = 'default') ->
    handlers =
      default : null
      vim     : @vimKeyboardHandler
      emacs   : @emacsKeyboardHandler

    @editor.setKeyboardHandler handlers[value]
    @appStorage.setValue 'keyboardHandler', value

  setScrollPastEnd: (value = yes) ->
    @editor.setOption 'scrollPastEnd', value
    @appStorage.setValue 'scrollPastEnd', value

  setFontSize:(value, save = yes)->

    @$("#editor#{@getId()}").css 'font-size', "#{value}px"
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


  setSoftWrap:(value, save = yes)->
    softWrapValueMap =
      'off'  : [ null, 80 ]
      '40'   : [ 40,   40 ]
      '80'   : [ 80,   80 ]
      'free' : [ null, 80 ]

    [limit, margin] = softWrapValueMap[value]

    @editor.getSession().setWrapLimitRange limit, limit
    @editor.renderer.setPrintMarginColumn margin
    @setUseWordWrap no if value is 'off'

    return  unless save
    @appStorage.setValue 'softWrap', value

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

  saveAllFiles: ->
    aceApp = KD.singletons.appManager.get 'Ace'
    return unless aceApp

    {aceViews} = aceApp.getView()

    for path, aceView of aceViews when aceView.data.parentPath isnt 'localfile:'
      aceView.ace.requestSave()
      aceView.ace.once 'FileContentSynced', -> @removeModifiedFromTab aceView

  removeModifiedFromTab:(aceView)->
    {name} = aceView.ace.data
    for handle in aceView.delegate.tabView.handles when handle.options.title is name
      handle.unsetClass 'modified'

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
