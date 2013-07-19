###
  todo:

    - fix setSoftWrap it goes back to off when you reopen the settings

###


class Ace extends KDView

  constructor:(options, file)->

    super options, file
    @lastSavedContents = ""
    @appStorage = KD.getSingleton('appStorageController').storage 'Ace', '1.0'

  setDomElement:(cssClass)->

    @domElement = $ "<figure class='kdview'><div id='editor#{@getId()}' class='code-wrapper'></div></figure>"

  viewAppended:->

    @hide()
    @appStorage.fetchStorage (storage)=>
      require ['ace/ace'], (ace)=>
        @fetchContents (err, contents)=>
          notification?.destroy()
          @editor = ace.edit "editor#{@getId()}"
          @prepareEditor()
          @utils.defer => @emit "ace.ready"
          if contents
            @setContents contents
            @lastSavedContents = contents
          @editor.on "change", =>
            if @isContentChanged() then @emit "FileContentChanged" else @emit "FileContentSynced"
          @editor.gotoLine 0
          @focus()
          @show()

  prepareEditor:->

    @setTheme()
    @setSyntax()
    @setEditorListeners()
    @appStorage.fetchStorage (storage)=>
      @setUseSoftTabs         @appStorage.getValue('useSoftTabs')         ? yes
      @setShowGutter          @appStorage.getValue('showGutter')          ? yes
      @setUseWordWrap         @appStorage.getValue('useWordWrap')         ? no
      @setShowPrintMargin     @appStorage.getValue('showPrintMargin')     ? no
      @setHighlightActiveLine @appStorage.getValue('highlightActiveLine') ? yes
      @setShowInvisibles      @appStorage.getValue('showInvisibles')      ? no
      @setSoftWrap            @appStorage.getValue('softWrap')            or 'off'
      @setFontSize            @appStorage.getValue('fontSize')            ? 12
      @setTabSize             @appStorage.getValue('tabSize')             ? 4

  setEditorListeners:->

    @editor.getSession().selection.on 'changeCursor', (cursor)=>
      @emit "ace.change.cursor", @editor.getSession().getSelection().getCursor()

    file = @getData()

    file.on "fs.save.finished", (err,res)=>
      unless err
        @notify "Successfully saved!", "success"
        @lastSavedContents = @lastContentsSentForSave
        @emit "FileContentSynced"
        unless @askedForSave
          log "this file has changed, put a modal and block editing @fatihacet!"
        @askedForSave = no

    file.on "fs.save.started", =>
      @lastContentsSentForSave = @getContents()

    file.on "fs.saveAs.finished", =>
      @emit "FileContentSynced"
      @emit "FileHasBeenSavedAs", file

    if @getOptions().enableShortcuts
      @addKeyCombo "save", "Ctrl-S", @bound "requestSave"

      @addKeyCombo "saveAs", "Ctrl-Shift-S", @bound "requestSaveAs"

      @addKeyCombo "find", "Ctrl-F", => @showFindReplaceView no

      @addKeyCombo "replace", "Ctrl-Shift-F", => @showFindReplaceView yes

      @addKeyCombo "compileAndRun", "Ctrl-Shift-C", => @getDelegate().compileAndRun()

      @addKeyCombo "preview", "Ctrl-Shift-P", => @getDelegate().preview()

    KD.getSingleton('windowController').on "keydown", (e) =>
      {findAndReplaceView} = @getDelegate()
      findAndReplaceView.close() if e.keyCode is 27 and findAndReplaceView


  showFindReplaceView: (openReplaceView) ->
    {findAndReplaceView} = @getDelegate()
    selectedText         = @editor.session.getTextRange @editor.getSelectionRange()
    findAndReplaceView.setViewHeight openReplaceView
    findAndReplaceView.setTextIntoFindInput selectedText
    findAndReplaceView.on "FindAndReplaceViewClosed", => @focus()

  addKeyCombo: (name, winKey, macKey, callback) ->
    if typeof macKey is "function"
      callback = macKey
      macKey   = winKey.replace "Ctrl", "Command"
    @editor.commands.addCommand
      name    : name
      bindKey :
        win   : winKey
        mac   : macKey
      exec    : => callback?()

  isContentChanged: ->
    return @getContents() isnt @lastSavedContents

  ###
  FS REQUESTS
  ###

  requestSave:->
    contents = @getContents()
    return @notify "Nothing to save!" unless @isContentChanged()
    @askedForSave = yes
    @emit "ace.requests.save", contents

  requestSaveAs:->
    contents = @getContents()
    @emit "ace.requests.saveAs", contents

  fetchContents:(callback)->
    file = @getData()
    unless /localfile:/.test file.path
      @notify "Loading...", null, null, 10000
      file.fetchContents callback
    else
      callback null, file.contents or ""

  ###
  GETTERS
  ###

  getContents:-> @editor.getSession().getValue()

  getTheme:-> @editor.getTheme().replace "ace/theme/", ""

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
    @appStorage.getValue('fontSize') ? parseInt @$("#editor#{@getId()}").css("font-size") ? 12, 10

  getTabSize:->
    @appStorage.getValue('tabSize') ? @editor.getSession().getTabSize()

  getUseWordWrap:->
    @appStorage.getValue('useWordWrap') ? @editor.getSession().getUseWrapMode()

  getSoftWrap:->

    limit = @appStorage.getValue('softWrap') ? @editor.getSession().getWrapLimitRange().max
    if limit then limit
    else
      if @getUseWordWrap() then "free" else "off"

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

  ###
  SETTERS
  ###

  setContents:(contents)-> @editor.getSession().setValue contents

  setTheme:(themeName)->
    themeName or= @appStorage.getValue('theme') or 'merbivore_soft'
    require ["ace/theme/#{themeName}"], (callback) =>
      @editor.setTheme "ace/theme/#{themeName}"
      @appStorage.setValue 'theme', themeName, =>
        callback

  setSyntax:(mode)->

    file = @getData()
    mode or= file.syntax

    unless mode
      ext  = FSItem.getFileExtension file.path
      for name, [language, extensions] of __aceSettings.syntaxAssociations
        if ///^(?:#{extensions})$///i.test ext
          mode = name
      mode or= "text"

    require ["ace/mode/#{mode}"], ({Mode})=>
      @editor.getSession().setMode new Mode
      @syntaxMode = mode

  setUseSoftTabs:(value)->

    @editor.getSession().setUseSoftTabs value
    @appStorage.setValue 'useSoftTabs', value

  setShowGutter:(value)->

    @editor.renderer.setShowGutter value
    @appStorage.setValue 'showGutter', value

  setShowPrintMargin:(value)->

    @editor.setShowPrintMargin value
    @appStorage.setValue 'showPrintMargin', value

  setHighlightActiveLine:(value)->

    @editor.setHighlightActiveLine value
    @appStorage.setValue 'highlightActiveLine', value

  # setHighlightSelectedWord:(value)-> @editor.setHighlightActiveLine value

  setShowInvisibles:(value)->

    @editor.setShowInvisibles value
    @appStorage.setValue 'showInvisibles', value

  setFontSize:(value, store = yes)->

    @$("#editor#{@getId()}").css 'font-size', "#{value}px"
    if store
      @appStorage.setValue 'fontSize', value

  setTabSize:(value)->
    @editor.getSession().setTabSize +value
    @appStorage.setValue 'tabSize', value

  setUseWordWrap:(value)->

    @editor.getSession().setUseWrapMode value
    @appStorage.setValue 'useWordWrap', value

  setSoftWrap:(value)->
    softWrapValueMap =
      'off'  : [ null, 80 ]
      '40'   : [ 40,   40 ]
      '80'   : [ 80,   80 ]
      'free' : [ null, 80 ]

    [limit, margin] = softWrapValueMap[value]

    @editor.getSession().setWrapLimitRange limit, limit
    @editor.renderer.setPrintMarginColumn margin
    @setUseWordWrap no if value is "off"

    @appStorage.setValue 'softWrap', value

  focus: -> @editor?.focus()

  ###
  HELPERS
  ###

  notification = null
  notify:(msg, style, details, duration)->

    notification.destroy() if notification

    style or= 'error' if details

    notification = new KDNotificationView
      title     : msg or "Something went wrong"
      type      : "mini"
      cssClass  : "#{style}"
      duration  : duration or if details then 5000 else 2500
      details   : details
      click     : ->
        if notification.getOptions().details
          details = new KDNotificationView
            title     : "Error details"
            content   : notification.getOptions().details
            type      : "growl"
            duration  : 0
            click     : -> details.destroy()

          KD.getSingleton('windowController').addLayer details

          details.on 'ReceivedClickElsewhere', =>
            details.destroy()
