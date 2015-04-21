$                    = require 'jquery'
_                    = require 'lodash'
getscript            = require 'getscript'
kd                   = require 'kd'
KDButtonView         = kd.ButtonView
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView   = kd.NotificationView
KDView               = kd.View
remote               = require('app/remote').getInstance()
globals              = require 'globals'
trackEvent           = require 'app/util/trackEvent'
FSHelper             = require 'app/util/fs/fshelper'
settings             = require './settings'

module.exports =

class Ace extends KDView

  ACE_READY = no

  @registerStaticEmitter()

  getscript globals.acePath, (err) =>
    throw err  if err

    for k, v of globals.aceConfig
      ace.config.set k, v

    ACE_READY = yes
    Ace.emit 'ScriptLoaded'


  toCommand = (obj, exec) ->

    # given a keyconfig model json and a callback, converts it to
    # conform to the ace command spec.
    #
    # main difference between keyconfig models and ace commands is, keyconfig
    # accepts multiple bindings while ace doesn't.
    #
    # see: https://github.com/ajaxorg/ace/blob/v1.1.4/lib/ace/commands/default_commands.js

    { shortcuts } = kd.singletons

    bindKey = {}
    bindKey[globals.keymapType] = obj.binding[0]
      .split '+'
      .map (frag) ->
        return "#{frag.charAt(0).toUpperCase()}#{frag.slice(1)}"
      .join '-'

    name    : obj.name
    exec    : exec
    bindKey : bindKey


  constructor: (options, file) ->

    super options, file

    @lastSavedContents     = ''
    {appStorageController} = kd.singletons
    @appStorage            = appStorageController.storage 'Ace', '1.0.1'


  setDomElement: (cssClass) ->

    @domElement = $ "<figure class='kdview'><div id='editor#{@getId()}' class='code-wrapper'></div></figure>"


  viewAppended: ->

    super

    @hide()

    @appStorage.fetchStorage (storage)=> # XXX: wtf? -og

    if ACE_READY
    then @scriptLoaded()
    else Ace.once 'ScriptLoaded', @bound 'scriptLoaded'


  scriptLoaded: ->

    @fetchContents (err, contents) =>

      notification?.destroy()
      element = @getElement().querySelector "#editor#{@getId()}"

      return  unless element

      @editor = ace.edit element

      element.classList.remove 'ace-tm' # remove default white theme to avoid flashing

      @prepareEditor()

      if contents
        @setContents contents
        @lastSavedContents = contents

      @editor.on 'change', =>
        @emit 'FileContentChanged'  unless @suppressListeners
        @emit 'FileContentRestored'  unless @isCurrentContentChanged()

      @editor.gotoLine 0

      @editor.commands.removeCommands [
        'gotoline'         # overriding this
        'sortlines'        # using same mapping for 'save all' action. XXX: re-map sortlines
        'showSettingsMenu' # f ace default settings menu
        'findprevious'     # we have our own find and replace dialogs
        'findnext'         # ace default for findnext is cmd+g (mapped to gotoline)
        'findAll'          # not used and collides with toggle filetree
        'restartSearch'
        'iSearch'
        'iSearchAndGo'
        'iSearchBackwardsAndGo'
        'recenterTopBottom'
        'selectAllMatches'
        'searchAsRegExp'
        'yankNextChar'
        'yankNextWord'
        'occurisearch'
        'cancelSearch'
        'confirmSearch'
        'shrinkSearchTerm'
        'extendSearchTermSpace'
        'searchBackward'
        'searchForward'
      ]

      @focus()
      @show()

      kd.utils.defer => @emit 'ace.ready'

      trackEvent 'Open Ace, success'

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


  prepareEditor: ->

    @setTheme null, no
    @setSyntax()
    @setEditorListeners()

    @appStorage.fetchStorage (storage) =>

      @setTheme()
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
      @setEnableAutocomplete  @appStorage.getValue('enableAutocomplete')  ? yes    ,no
      @setEnableSnippets      @appStorage.getValue('enableSnippets')      ? yes    ,no


  saveStarted: ->

    @lastContentsSentForSave = @getContents()


  saveFinished:(res)->

    @lastSavedContents = @lastContentsSentForSave
    @emit 'FileContentRestored'
    # unless @askedForSave
      # log "this file has changed, put a modal and block editing @fatihacet!"
      # fatihacet - this case works buggy.
    @askedForSave = no


  saveAsFinished: (newFile, oldFile) ->

    @emit 'FileContentRestored'
    @emit 'FileHasBeenSavedAs', @getData()


  setEditorListeners: ->

    @editor.getSession().selection.on 'changeCursor', (cursor) =>
      return if @suppressListeners
      @emit 'ace.change.cursor', @editor.getSession().getSelection().getCursor()

    @editor.commands.on 'afterExec', (e) =>
      if e.command.name is 'insertstring' and /^[\w.]$/.test e.args
        @editor.completer and @editor.completer.autoInsert = off
        @editor.execCommand 'startAutocomplete'

    {enableShortcuts} = @getOptions()

    if enableShortcuts

      { shortcuts }                = kd.singletons
      { createFindAndReplaceView } = @getOptions()

      shortcuts
        .getJSON 'editor', (model) -> model.options?.overrides_ace
        .forEach (model) =>
          key = model.name

          cb  =
          switch key

            when 'save'     then @requestSave.bind this
            when 'saveAs'   then @requestSaveAs.bind this
            when 'gotoLine' then @showGotoLine.bind this
            else
              if match = /^find$|^replace$/.exec key
                replace = match.input is 'replace'
                if createFindAndReplaceView
                  @showFindReplaceView.bind this, replace
                else
                  @emit.bind this, 'FindAndReplaceViewRequested', replace

          return  unless cb
          
          @editor.commands.addCommand toCommand(model, cb)


  showFindReplaceView: (openReplaceView) ->
    {findAndReplaceView} = @getDelegate()
    selectedText         = @editor.session.getTextRange @editor.getSelectionRange()
    findAndReplaceView.setViewHeight openReplaceView
    findAndReplaceView.setTextIntoFindInput selectedText
    findAndReplaceView.on 'FindAndReplaceViewClosed', => @focus()


  isContentChanged: -> @contentChanged


  isCurrentContentChanged:-> @getContents() isnt @lastSavedContents


  closeTab: ->

    aceView   = @getDelegate()
    {tabView} = aceView.getDelegate()
    tabView.removePane_ tabView.getActivePane()


  ###
  FS REQUESTS
  ###

  requestSave: ->

    contents = @getContents()

    unless contents is '' or @isContentChanged()
      if @getDelegate().parent.active
        @notify 'Nothing to save!'
      return

    @askedForSave = yes
    @emit 'ace.requests.save', contents


  requestSaveAs: ->

    @emit 'ace.requests.saveAs', @getContents()


  fetchContents: (callback) ->

    file = @getData()

    unless /localfile:/.test file.path
      file.fetchContents callback
    else
      callback null, file.contents or ''


  ###
  GETTERS
  ###

  getContents: ->
    @editor.getSession().getValue()


  getTheme: ->
    @editor.getTheme().replace 'ace/theme/', ''


  getSyntax: -> @syntaxMode


  getUseSoftTabs: ->
    @appStorage.getValue('useSoftTabs') ? @editor.getSession().getUseSoftTabs()


  getShowGutter: ->
    @appStorage.getValue('showGutter') ? @editor.renderer.getShowGutter()


  getShowPrintMargin: ->
    @appStorage.getValue('showPrintMargin') ? @editor.getShowPrintMargin()


  getHighlightActiveLine: ->
    @appStorage.getValue('highlightActiveLine') ? @editor.getHighlightActiveLine()


  getShowInvisibles: ->
    @appStorage.getValue('showInvisibles') ? @editor.getShowInvisibles()


  getFontSize: ->
    @appStorage.getValue('fontSize') ? parseInt @$("#editor#{@getId()}").css('font-size') ? 12, 10


  getTabSize: ->
    @appStorage.getValue('tabSize') ? @editor.getSession().getTabSize()


  getUseWordWrap: ->
    @appStorage.getValue('useWordWrap') ? @editor.getSession().getUseWrapMode()


  getKeyboardHandler: ->
    @appStorage.getValue('keyboardHandler') ? 'default'


  getScrollPastEnd: ->
    @appStorage.getValue('scrollPastEnd') ? yes


  getOpenRecentFiles: ->
    @appStorage.getValue('openRecentFiles') ? yes


  getEnableAutocomplete: ->
    @appStorage.getValue('enableAutocomplete') ? yes


  getSettings: ->

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
    enableAutocomplete  : @getEnableAutocomplete()


  ###
  SETTERS
  ###

  setContents: (contents) ->
    @editor.getSession().setValue contents


  setSyntax: (mode) ->

    file = @getData()
    mode or= file.syntax

    unless mode
      ext  = FSHelper.getFileExtension file.path
      for own name, [language, extensions] of settings.syntaxAssociations
        if ///^(?:#{extensions})$///i.test ext
          mode = name

      syntaxChoice = @appStorage.getValue "syntax_#{ext}"
      mode = syntaxChoice or mode or 'text'

    @editor.getSession().setMode "ace/mode/#{mode}"
    @syntaxMode = mode


  setTheme: (themeName, save = yes) ->

    themeName or= @appStorage.getValue('theme') or 'base16'

    @editor.setTheme "ace/theme/#{themeName}"
    return  unless save
    @appStorage.setValue 'theme', themeName, => # do what is necessary here if any - SY


  setUseSoftTabs: (value, save = yes) ->

    @editor.getSession().setUseSoftTabs value
    return  unless save
    @appStorage.setValue 'useSoftTabs', value


  setShowGutter: (value, save = yes) ->

    @editor.renderer.setShowGutter value
    return  unless save
    @appStorage.setValue 'showGutter', value


  setShowPrintMargin: (value, save = yes) ->

    @editor.setShowPrintMargin value
    return  unless save
    @appStorage.setValue 'showPrintMargin', value


  setHighlightActiveLine: (value, save = yes) ->

    @editor.setHighlightActiveLine value
    return  unless save
    @appStorage.setValue 'highlightActiveLine', value


  # setHighlightSelectedWord:(value)-> @editor.setHighlightActiveLine value


  setShowInvisibles: (value, save = yes) ->

    @editor.setShowInvisibles value
    return  unless save
    @appStorage.setValue 'showInvisibles', value


  setKeyboardHandler: (name = 'default') ->

    @appStorage.setValue 'keyboardHandler', name
    handler = if name isnt 'default' then "ace/keyboard/#{name}" else null
    @editor.setKeyboardHandler handler


  setScrollPastEnd: (value = yes) ->

    @editor.setOption 'scrollPastEnd', value
    @appStorage.setValue 'scrollPastEnd', value


  setFontSize: (value, save = yes) ->

    return if value is globals.config.oldFontSize

    style           = global.document.createElement 'style'
    style.id        = 'ace-font-size'
    style.innerHTML = ".ace_editor { font-size: #{value}px }"

    oldStyleTag     = global.document.getElementById style.id
    oldStyleTag.parentNode.removeChild oldStyleTag if oldStyleTag

    global.document.head.appendChild style
    globals.config.oldFontSize = value

    return  unless save
    @appStorage.setValue 'fontSize', value


  setTabSize: (value, save = yes) ->

    @editor.getSession().setTabSize +value
    return  unless save
    @appStorage.setValue 'tabSize', value


  setUseWordWrap: (value, save = yes) ->

    @editor.getSession().setUseWrapMode value
    return  unless save
    @appStorage.setValue 'useWordWrap', value


  setReadOnly: (value) ->
    @editor.setReadOnly value


  setOpenRecentFiles: (value, save = yes) ->
    @appStorage.setValue 'openRecentFiles', value


  setEnableSnippets: (value, save = yes) ->

    @editor.setOption 'enableSnippets', value
    @appStorage.setValue 'enableSnippets', value  if save


  setEnableAutocomplete: (value, save = yes) ->

    @editor.setOption 'enableBasicAutocompletion', value
    @appStorage.setValue 'enableAutocomplete', value  if save


  gotoLine: (lineNumber) ->
    @editor.gotoLine lineNumber


  focus: -> @editor?.focus()


  ###
  HELPERS
  ###

  notification = null

  notify: (msg, style, details, duration) ->

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

          kd.getSingleton('windowController').addLayer details

          details.on 'ReceivedClickElsewhere', =>
            details.destroy()


  #obsolete: Now we are using IDE saveAllFiles method
  saveAllFiles: ->
    aceApp = kd.singletons.appManager.get 'Ace'
    return unless aceApp

    {aceViews} = aceApp.getView()

    for path, aceView of aceViews when aceView.data.parentPath isnt 'localfile:'
      aceView.ace.requestSave()
      aceView.ace.once 'FileContentRestored', @bound 'removeModifiedFromTab'


  removeModifiedFromTab: ->

    aceView      = @parent

    unless aceView
      # happens when collab is active and when you have tabs open
      # and when you reload the page - SY
      kd.warn 'possible race condition, shadowing the error! @acet'
      return

    {name}       = aceView.ace.data
    {handles}    = aceView.delegate.tabView
    targetHandle = null

    for handle in handles when handle.getOptions().title is name
      targetHandle = handle
      targetHandle.setClass 'saved'

      kd.utils.wait 500, ->
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
