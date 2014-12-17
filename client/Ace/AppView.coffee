###
  todo:

    - make save dialog a view with pistachio
    - put listeners in methods
    - make this splittable

###

class AceView extends JView

  constructor: (options = {}, file) ->

    super options, file

    options.advancedSettings         ?= no
    options.createBottomBar          ?= yes
    options.createFindAndReplaceView ?= yes

    @listenWindowResize()

    aceOptions        =
      delegate        : options.delegate or this
      enableShortcuts : yes
      createFindAndReplaceView : options.createFindAndReplaceView

    @ace = new Ace aceOptions, file

    if options.createFindAndReplaceView
      @findAndReplaceView = new AceFindAndReplaceView delegate: this
      @findAndReplaceView.hide()
    else
      @findAndReplaceView = new KDCustomHTMLView

    if @getOption 'createBottomBar'
      @caretPosition  = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : 'caret-position section'
        partial       : '<span>1</span>:<span>1</span>'

    @advancedSettings = new KDButtonViewWithMenu
      style           : 'editor-advanced-settings-menu'
      icon            : yes
      iconOnly        : yes
      iconClass       : 'cog'
      type            : 'contextmenu'
      delegate        : options.delegate or this
      itemClass       : AceSettingsView
      click           : (pubInst, event) -> @contextMenu event
      menu            : @getAdvancedSettingsMenuItems.bind this

    @advancedSettings.disable()

    @advancedSettings.hide()  unless options.advancedSettings

    @setViewListeners()

  setViewListeners:->
    hasBottomBar = @getOptions().createBottomBar

    @ace.on 'ace.ready', @advancedSettings.bound 'enable'

    @ace.on 'ace.changeSetting', (setting, value) =>
      @ace["set#{setting.capitalize()}"]? value

    @advancedSettings.emit 'ace.settingsView.setDefaults', @ace

    if hasBottomBar
      $spans = @caretPosition.$ 'span'

      @ace.on 'ace.change.cursor', (cursor) =>
        $spans.eq(0).text ++cursor.row
        $spans.eq(1).text ++cursor.column

    @ace.on 'ace.requests.saveAs', (contents, options) =>
      @openSaveDialog options

    @ace.on "ace.requests.save", (contents) =>
      file = @getData()
      if /localfile:/.test file.path
        @openSaveDialog()
      else
        file.once 'fs.save.started',    @ace.bound 'saveStarted'
        file.once 'fs.save.finished',   @ace.bound 'saveFinished'
        file.emit 'file.requests.save', contents

    @ace.on 'FileContentChanged', =>
      @ace.contentChanged = yes
      @getActiveTabHandle().setClass 'modified'
      @getDelegate().quitOptions =
        message : 'You have unsaved changes. You will lose them if you close this tab.'
        title   : 'Do you want to close this tab?'

    @ace.on 'FileContentSynced', =>
      @ace.contentChanged = no
      @getActiveTabHandle().unsetClass 'modified'
      delete @getDelegate().quitOptions

    @on 'KDObjectWillBeDestroyed', =>
      file = @getData()
      KD.singletons.localSync.removeFromOpenedFiles file
      @getDelegate().removeOpenDocument @

    @ace.on 'ace.changeSetting', (setting, value)->
      if setting is 'syntax'
        file = @getData()
        fileExtension = file.getExtension()
        appStorage = KD.getSingleton('appStorageController').storage 'Ace', '1.0.1'
        appStorage.setValue "syntax_#{fileExtension}", value

    @ace.on 'FileIsReadOnly', =>
      @getActiveTabHandle().setClass 'readonly'
      @ace.setReadOnly yes
      modal             = new KDModalView
        title           : 'This file is readonly'
        content         : """
        <div class="modalformline">
          <p>
            The file <code>#{@getData().name}</code> is set to readonly,
            you won't be able to save your changes.
          </p>
        </div>
        """
        buttons         :
          'Edit Anyway' :
            cssClass    : 'modal-clean-red'
            callback    : =>
              @ace.setReadOnly no
              modal.destroy()
          'Cancel'      :
            cssClass    : 'modal-cancel'
            callback    : ->
              modal.destroy()

  getActiveTabHandle: ->
    return  @getDelegate().tabView.getActivePane().tabHandle

  toggleFullscreen: ->
    mainView = KD.getSingleton 'mainView'
    mainView.toggleFullscreen()

  getAdvancedSettingsMenuItems:->
    settings      :
      type        : 'customView'
      view        : new AceSettingsView
        delegate  : @ace

  openSaveDialog: ->

    file = @getData()
    container = @getOptions().delegate or this

    KD.utils.showSaveDialog container, (input, finderController, dialog) =>

      [node] = finderController.treeController.selectedNodes
      name   = input.getValue()

      return @ace.notify 'Please type valid file name!'   , 'error'  unless FSHelper.isValidFileName name
      return @ace.notify 'Please select a folder to save!', 'error'  unless node

      dialog.overlay.destroy()
      dialog.destroy()

      parent            = node.getData()
      contents          = @ace.getContents()
      oldCursorPosition = @ace.editor.getCursorPosition()

      file.machine = parent.machine

      file.emit 'file.requests.saveAs', contents, name, parent.path
      file.once 'fs.saveAs.finished',   @ace.bound 'saveAsFinished'
      @ace.emit 'AceDidSaveAs', name, parent.path

      file.on 'fs.saveAs.finished', (newFile) =>

        {tabView} = @getDelegate()
        return  if tabView.willClose

        @getDelegate().openFile newFile, contents

    , { inputDefaultValue: file.name }

  _windowDidResize:->
    height = @getHeight()
    bottomBarHeight = @$('.editor-bottom-bar').height()
    newHeight = height - bottomBarHeight
    @ace.setHeight newHeight unless newHeight is 0

  viewAppended:->
    super

    @_windowDidResize()

  pistachio:->
    hasBottomBar = @getOption 'createBottomBar'
    template     = """
      <div class="kdview editor-main">
        {{> @ace}}
        {{> @findAndReplaceView}}
      </div>
    """

    if hasBottomBar
      template = """
        <div class="kdview editor-main">
          {{> @ace}}
          <div class="editor-bottom-bar clearfix">
            {{> @caretPosition}}
            {{> @advancedSettings}}
          </div>
          {{> @findAndReplaceView}}
        </div>
      """

    return template
