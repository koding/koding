$                    = require 'jquery'
_                    = require 'lodash'
getscript            = require '@koding/getscript'
kd                   = require 'kd'
KDButtonView         = kd.ButtonView
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView   = kd.NotificationView
KDView               = kd.View
globals              = require 'globals'
FSHelper             = require 'app/util/fs/fshelper'
settings             = require './settings'

prependWithOrigin = (path) -> [location.origin, path].join '/'

module.exports =

class Ace extends KDView

  ACE_READY = no

  EmmetLoadState =
    PENDING: no
    READY  : no


  emmetLoadListeners = {}

  @registerStaticEmitter()

  getscript prependWithOrigin(globals.acePath), (err) ->
    throw err  if err

    for k, v of globals.aceConfig
      ace.config.set k, prependWithOrigin(v)

    ACE_READY = yes
    Ace.emit 'ScriptLoaded'


  toBindKey = (binding) ->

    bindKey = {}
    bindKey[globals.keymapType] = binding
      .split '+'
      .map (frag) ->
        return "#{frag.charAt(0).toUpperCase()}#{frag.slice(1)}"
      .join '-'


  # Given a keyconfig model json and a callback, converts it to conform to the ace command spec.
  #
  # See: https://github.com/ajaxorg/ace/blob/v1.1.4/lib/ace/commands/default_commands.js
  #
  toCommand = (model, exec) ->

    binding = model.binding[0]

    # Since shortcuts#change emits a raw keyconfig.Model, binding prop might include
    # all bindings for all platforms.
    #
    # In that case we need to get platform bindings explicitly:
    if _.isArray binding
      { shortcuts } = kd.singletons
      binding = shortcuts.getPlatformBinding(model)[0]

    return {
      name    : model.name
      exec    : exec
      bindKey : toBindKey binding
    }


  constructor: (options, file) ->

    super options, file

    @lastSavedContents       = ''
    { appStorageController } = kd.singletons
    @appStorage              = appStorageController.storage 'Ace', '1.0.1'


  setDomElement: (cssClass) ->

    @domElement = $ "<figure class='kdview'><div id='editor#{@getId()}' class='code-wrapper'></div></figure>"


  viewAppended: ->

    super

    @hide()

    @appStorage.fetchStorage (storage) -> # XXX: wtf? -og

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

      if contents
        @setContents contents
        @lastSavedContents = contents

      @editor.on 'change', =>
        @emit 'FileContentChanged'   unless @suppressListeners
        @emit 'FileContentRestored'  unless @isCurrentContentChanged()

      @editor.gotoLine 0

      @prepareEditor()

      @focus()
      @show()

      kd.utils.defer @lazyBound 'emit', 'ready'

    @ready =>
      LineWidgets = ace.require('ace/line_widgets').LineWidgets
      @Range      = ace.require('ace/range').Range
      @Anchor     = ace.require('ace/anchor').Anchor

      @lineWidgetManager = new LineWidgets @editor.session
      @lineWidgetManager.attach @editor


  setContent: (content, emitFileContentChangedEvent = yes) ->

    @suppressListeners = yes  unless emitFileContentChangedEvent

    @editor.setValue content, -1

    @suppressListeners = no   unless emitFileContentChangedEvent


  destroy: ->

    { shortcuts } = kd.singletons
    shortcuts.removeListener 'change', @bound 'handleShortcutChange'
    emmetLoadListeners[@id] = null  unless _.isNull emmetLoadListeners

    @_commandFns = null

    super


  prepareEditor: ->

    @setTheme null, no
    @setSyntax()
    @setEditorListeners()
    @setShortcuts yes

    @appStorage.fetchStorage (storage) =>
      @setTheme null, no
      @setUseSoftTabs         @appStorage.getValue('useSoftTabs')         ? yes       , no
      @setShowGutter          @appStorage.getValue('showGutter')          ? yes       , no
      @setUseWordWrap         @appStorage.getValue('useWordWrap')         ? no        , no
      @setShowPrintMargin     @appStorage.getValue('showPrintMargin')     ? no        , no
      @setHighlightActiveLine @appStorage.getValue('highlightActiveLine') ? yes       , no
      @setShowInvisibles      @appStorage.getValue('showInvisibles')      ? no        , no
      @setFontSize            @appStorage.getValue('fontSize')            ? 12        , no
      @setTabSize             @appStorage.getValue('tabSize')             ? 4         , no
      @setKeyboardHandler     @appStorage.getValue('keyboardHandler')     ? 'default' , no
      @setScrollPastEnd       @appStorage.getValue('scrollPastEnd')       ? yes       , no
      @setEnableAutocomplete  @appStorage.getValue('enableAutocomplete')  ? yes       , no
      @setEnableSnippets      @appStorage.getValue('enableSnippets')      ? yes       , no
      @setEnableEmmet         @appStorage.getValue('enableEmmet')         ? no        , no

      @isTrimWhiteSpacesEnabled = if @appStorage.getValue('trimTrailingWhitespaces') then yes else no

      @emit 'SettingsApplied'


  saveStarted: ->

    @lastContentsSentForSave = @getContents()


  saveFinished: (res) ->

    @lastSavedContents = @lastContentsSentForSave
    @emit 'FileContentRestored'


  saveAsFinished: (newFile, oldFile) ->

    @emit 'FileContentRestored'
    @emit 'FileHasBeenSavedAs', @getData()


  handleShortcutChange: (collection, model) ->

    return  if collection.name isnt 'editor'
    @setShortcut model


  setShortcuts: (removeObsolete = yes) ->

    # A stupid workaround to keep commands since ace@1.1.4#removeCommand
    # deletes a command's exec ref.
    @_commandFns = _.reduce @editor.commands.commands, (acc, val, key) ->
      acc[key] = val.exec
      return acc
    , {}

    { shortcuts } = kd.singletons

    collection = shortcuts.toCollection().find { _key: 'editor' }
    names = collection.map (model) -> model.name

    if removeObsolete
      obsolete = [
        'sortlines' # XXX
        'showSettingsMenu'
        'findprevious'
        'findnext'
        'findAll'
        'toggleFoldWidget'
        'toggleParentFoldWidget'
        'passKeysToBrowser'
        'jumptomatching'
        'selecttomatching'
        'expandToMatching'
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
        'restartSearch'
        'searchBackward'
        'searchForward'
        'shrinkSearchTerm'
        'extendSearchTermSpace'
      ]

      # make sure we are not removing an already overridden shortcut
      @editor.commands.removeCommands _.filter obsolete, (key) ->
        !~_.indexOf names, key

    collection.each (model) => @setShortcut model


  setShortcut: (model) ->

    disabled = model.options?.enabled is no

    if disabled
      @editor.commands.removeCommand model.name
      return

    key = model.name
    exec =
    switch key
      when 'save'     then @requestSave.bind this
      when 'saveas'   then @requestSaveAs.bind this
      when 'gotoline' then @showGotoLine.bind this
      else
        { createFindAndReplaceView } = @getOptions()
        if match = /^find$|^replace$/.exec key
          replace = match.input is 'replace'
          if createFindAndReplaceView
            @showFindReplaceView.bind this, replace
          else
            @emit.bind this, 'FindAndReplaceViewRequested', replace

    exec or= @_commandFns[model.name]
    @editor.commands.addCommand toCommand(model, exec)


  getCursor: ->

    return  @editor.getSession().getSelection().getCursor()


  setEditorListeners: ->

    { shortcuts } = kd.singletons
    shortcuts.on 'change', @bound 'handleShortcutChange'

    @editor.getSession().selection.on 'changeCursor', (cursor) =>
      return if @suppressListeners
      @emit 'ace.change.cursor', @getCursor()

    @editor.commands.on 'afterExec', (e) =>
      if e.command.name is 'insertstring' and /^[\w.]$/.test e.args
        @editor.completer and @editor.completer.autoInsert = off
        @editor.execCommand 'startAutocomplete'


  showFindReplaceView: (openReplaceView) ->

    { findAndReplaceView } = @getDelegate()
    selectedText           = @editor.session.getTextRange @editor.getSelectionRange()

    findAndReplaceView.show openReplaceView
    findAndReplaceView.setTextIntoFindInput selectedText
    findAndReplaceView.on 'FindAndReplaceViewClosed', => @focus()


  isContentChanged: -> @contentChanged


  isCurrentContentChanged: -> @getContents() isnt @lastSavedContents


  closeTab: ->

    aceView     = @getDelegate()
    { tabView } = aceView.getDelegate()
    tabView.removePane_ tabView.getActivePane()


  setTrimTrailingWhitespaces: (value) -> @isTrimWhiteSpacesEnabled = value


  setEnableBraceCompletion: (state) -> @editor.setBehavioursEnabled state


  ###
  FS REQUESTS
  ###

  requestSave: (options = {}) ->

    options.ignoreActiveLineOnTrim ?= no

    contents = @getContents()

    if @isTrimWhiteSpacesEnabled
      @trimTrailingWhitespaces options.ignoreActiveLineOnTrim
      contents = @getContents()

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


  getEnableAutocomplete: ->
    @appStorage.getValue('enableAutocomplete') ? yes


  getEnableSnippets: ->
    @appStorage.getValue('enableSnippets') ? yes


  getEnableEmmet: ->
    @appStorage.getValue('enableEmmet') ? no

  getEnableBraceCompletion: ->
    @appStorage.getValue('enableBraceCompletion') ? yes


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
    enableAutocomplete  : @getEnableAutocomplete()
    enableSnippets      : @getEnableSnippets()
    enableEmmet         : @getEnableEmmet()


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
    @appStorage.setValue 'theme', themeName, -> # do what is necessary here if any - SY


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


  setKeyboardHandler: (name = 'default', save = yes) ->

    handler = if name isnt 'default' then "ace/keyboard/#{name}" else null
    @editor.setKeyboardHandler handler
    @appStorage.setValue 'keyboardHandler', name  if save


  setScrollPastEnd: (value = yes, save = yes) ->

    @editor.setOption 'scrollPastEnd', value
    @appStorage.setValue 'scrollPastEnd', value  if save


  setFontSize: (value, save = yes) ->

    return if value is globals.config.oldFontSize

    style           = global.document.createElement 'style'
    style.id        = 'ace-font-size'
    style.innerHTML = ".ace_editor { font-size: #{value}px }"

    @editor.setFontSize value

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


  setReadOnly: (value) -> @editor.setReadOnly value


  loadEmmet: (cb) ->

    return cb null  if EmmetLoadState.READY

    emmetLoadListeners[@id] = cb

    if not EmmetLoadState.PENDING
      EmmetLoadState.PENDING = yes
      emmetPath = globals.acePath.split('/').slice(0, -1)
        .concat(['_ext-emmet.js']).join('/')

      getscript prependWithOrigin(emmetPath), (err) ->
        cb err for key, cb of emmetLoadListeners when typeof cb is 'function'
        EmmetLoadState.READY = yes
        emmetLoadListeners = null


  setEnableEmmet: (value, save = yes) ->

    next = (err) =>
      throw err  if err
      @editor.setOption 'enableEmmet', value  if value
      @appStorage.setValue 'enableEmmet', value  if save

    if value is yes and not EmmetLoadState.READY
      @loadEmmet next
    else
      next null


  setEnableSnippets: (value, save = yes) ->

    @editor.setOption 'enableSnippets', value
    @appStorage.setValue 'enableSnippets', value  if save


  setEnableAutocomplete: (value, save = yes) ->

    @editor.setOption 'enableBasicAutocompletion', value
    @appStorage.setValue 'enableAutocomplete', value  if save


  gotoLine: (lineNumber) -> @editor.gotoLine lineNumber


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

          details.on 'ReceivedClickElsewhere', ->
            details.destroy()



  removeModifiedFromTab: ->

    @emit 'RemoveModifiedFromTab', @getData().path


  trimTrailingWhitespaces: (ignoreActiveLine) ->

    doc       = @editor.getSession().getDocument()
    lines     = doc.getAllLines()
    activeRow = @getCursor().row  if ignoreActiveLine

    for line, lineNumber in lines
      whiteSpaceIndex = line.search /\s+$/

      if whiteSpaceIndex > -1
        if activeRow?
          if activeRow isnt lineNumber
            doc.removeInLine lineNumber, whiteSpaceIndex, line.length
        else
          doc.removeInLine lineNumber, whiteSpaceIndex, line.length


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
                      style         : 'GenericButton'
                      type          : 'submit'

      @gotoLineModal.on 'KDModalViewDestroyed', =>
        @gotoLineModal = null
        @focus()

      @gotoLineModal.modalTabs.forms.Go.focusFirstElement()
