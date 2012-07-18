###
  todo:
    
    - put search replace
    - fix setSoftWrap it goes back to off when you reopen the settings

###


class Ace extends KDView
  
  constructor:(options, file)->
    
    super options, file
    @lastSavedContents = ""

  setDomElement:(cssClass)->

    @domElement = $ "<figure class='kdview'><div id='editor#{@getId()}' class='code-wrapper'></div></figure>"

  viewAppended:->
    
    require ['ace/ace'], (ace)=>
      @editor = ace.edit "editor#{@getId()}"
      @prepareEditor()
      @utils.wait => @emit "ace.ready"
      @fetchContents (err, contents)=>
        @setContents contents if contents
        @editor.gotoLine 0


  prepareEditor:->
    
    @setTheme()
    @setSyntax()
    @setShowPrintMargin no
    @setEditorListeners()
  
  setEditorListeners:->
    @editor.getSession().selection.on 'changeCursor', (cursor)=>
      @emit "ace.change.cursor", @editor.getSession().getSelection().getCursor()
    
    @editor.commands.addCommand
        name    : 'save'
        bindKey :
          win   : 'Ctrl-S'
          mac   : 'Command-S'
        exec    : => @requestSave()

    @editor.commands.addCommand
        name    : 'save as'
        bindKey :
          win   : 'Ctrl-Shift-S'
          mac   : 'Command-Shift-S'
        exec    : => @requestSaveAs()

    file = @getData()

    file.on "fs.save.finished", (err,res)=>
      unless err
        @notify "Successfully saved!", "success"
        @lastSavedContents = @lastContentsSentForSave

    file.on "fs.save.started", =>
      @lastContentsSentForSave = @getContents()
  
  ###
  FS REQUESTS
  ###
        
  requestSave:->

    contents = @getContents()
    return @notify "Nothing to save!" unless contents isnt @lastSavedContents
    @emit "ace.requests.save", contents

  requestSaveAs:->

    contents = @getContents()
    @emit "ace.requests.saveAs", contents

    
  fetchContents:(callback)->
    
    file = @getData()
    unless /localfile:/.test file.path
      file.fetchContents callback
    else
      callback null, file.contents or ""
    
  ###
  GETTERS
  ###
  
  getContents:-> @editor.getSession().getValue()
  
  getTheme:-> @editor.getTheme().replace "ace/theme/", ""

  getSyntax:-> @syntaxMode

  getUseSoftTabs:-> @editor.getSession().getUseSoftTabs()

  getShowGutter:-> @editor.renderer.getShowGutter()

  getShowPrintMargin:-> @editor.getShowPrintMargin()

  getHighlightActiveLine:-> @editor.getHighlightActiveLine()

  getShowInvisibles:-> @editor.getShowInvisibles()

  getFontSize:-> parseInt @$("#editor#{@getId()}").css("font-size"), 10

  getTabSize:-> @editor.getSession().getTabSize()

  getUseWordWrap:-> @editor.getSession().getUseWrapMode()

  getSoftWrap:-> 

    limit = @editor.getSession().getWrapLimitRange().max
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

  setTheme:(themeName = "merbivore_soft")->

    require ["ace/theme/#{themeName}"], (callback) =>
      @editor.setTheme "ace/theme/#{themeName}"
  
  setSyntax:(mode)->
    
    file = @getData()
    mode or= file.syntax
    
    unless mode
      ext  = @utils.getFileExtension file.path
      for name, [language, extensions] of __aceSettings.syntaxAssociations
        if ///^(?:#{extensions})$///i.test ext
          mode = name
      mode or= "text"
    
    require ["ace/mode/#{mode}"], ({Mode})=>
      @editor.getSession().setMode new Mode
      @syntaxMode = mode

  setUseSoftTabs:(value)-> @editor.getSession().setUseSoftTabs value
    
  setShowGutter:(value)-> @editor.renderer.setShowGutter value

  setShowPrintMargin:(value)-> @editor.setShowPrintMargin value
    
  setHighlightActiveLine:(value)-> @editor.setHighlightActiveLine value

  # setHighlightSelectedWord:(value)-> @editor.setHighlightActiveLine value

  setShowInvisibles:(value)-> @editor.setShowInvisibles value

  setFontSize:(value)-> @$("editor#{@getId()}").css fontSize : "#{value}px"

  setTabSize:(value)-> @editor.getSession().setTabSize value

  setUseWordWrap:(value)-> @editor.getSession().setUseWrapMode value
  
  softWrapValueMap = ->

    'off'  : [ null, 80 ]
    '40'   : [ 40,   40 ]
    '80'   : [ 80,   80 ]
    'free' : [ null, 80 ]
  
  setSoftWrap:(value)->
    
    [limit, margin] = softWrapValueMap()[value]

    @editor.getSession().setWrapLimitRange limit, limit
    @editor.renderer.setPrintMarginColumn margin
    @setUseWordWrap no if value is "off"

  ###
  HELPERS
  ###

  notification = null
  notify:(msg, style, details)->

    notification.destroy() if notification
    
    style or= 'error' if details
    
    notification = new KDNotificationView
      title     : msg or "Something went wrong"
      type      : "mini"
      cssClass  : "editor #{style}"
      container : @parent
      duration  : if details then 5000 else 2500
      details   : details
      click     : ->
        if notification.getOptions().details
          details = new KDNotificationView
            title     : "Error details"
            content   : notification.getOptions().details
            type      : "growl"
            duration  : 0
            click     : -> details.destroy()

          @getSingleton('windowController').addLayer details

          details.on 'ReceivedClickElsewhere', =>
            details.destroy()
