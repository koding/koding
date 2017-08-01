kd                        = require 'kd'
KDButtonViewWithMenu      = kd.ButtonViewWithMenu
KDCustomHTMLView          = kd.CustomHTMLView
KDModalView               = kd.ModalView

FSHelper                  = require 'app/util/fs/fshelper'
Ace                       = require './ace'
AceFindAndReplaceView     = require './acefindandreplaceview'
AceSettingsView           = require './acesettingsview'
showSaveDialog            = require 'app/util/showSaveDialog'
Encoder                   = require 'htmlencode'


###
  todo:

    - make save dialog a view with pistachio
    - put listeners in methods
    - make this splittable

###


module.exports = class AceView extends kd.View

  constructor: (options = {}, file) ->


    options.aceClass                or= Ace
    options.advancedSettings         ?= no
    options.createBottomBar          ?= yes
    options.createFindAndReplaceView ?= yes
    options.useStorage               ?= yes

    super options, file

    @listenWindowResize()

    aceOptions = {
      createFindAndReplaceView
      advancedSettings
      useStorage
      delegate
    } = @getOptions()

    aceOptions.delegate ?= delegate ?= this

    @ace = new options.aceClass aceOptions, file

    if createFindAndReplaceView
      @findAndReplaceView = new AceFindAndReplaceView { delegate: this }
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
      delegate        : delegate
      itemClass       : AceSettingsView
      click           : (pubInst, event) -> @contextMenu event
      menu            : @getAdvancedSettingsMenuItems.bind this

    @advancedSettings.disable()
    @advancedSettings.hide()  unless advancedSettings

    @setViewListeners()


  getDelegate: -> @delegate ? {}


  forEachPaneByFile: (path, callback) ->

    return  unless @getDelegate().tabView

    { handles, panes } = @getDelegate().tabView

    for pane in panes when pane.getData()?.path is path
      callback pane


  showModifiedIconOnTabHandle: ->

    { path } = @ace.getData()
    @forEachPaneByFile path, (pane) -> pane.tabHandle.setClass 'modified'


  removeModifiedFromTab: (path) ->

    @forEachPaneByFile path, (pane) ->
      { tabHandle } = pane
      tabHandle.setClass 'saved'

      kd.utils.wait 522, ->
        tabHandle.unsetClass 'modified'
        tabHandle.unsetClass 'saved'


  setViewListeners: ->

    hasBottomBar = @getOptions().createBottomBar

    @ace.ready @advancedSettings.bound 'enable'

    @ace.on 'ace.changeSetting', (setting, value) =>
      @ace["set#{setting.capitalize()}"]? value

    @advancedSettings.emit 'ace.settingsView.setDefaults', @ace

    if hasBottomBar
      $spans = @caretPosition.$ 'span'

      @ace.on 'ace.change.cursor', (cursor) ->
        $spans.eq(0).text ++cursor.row
        $spans.eq(1).text ++cursor.column

    @ace.on 'ace.requests.saveAs', (contents, options) =>
      @openSaveDialog options

    @ace.on 'ace.requests.save', (contents) =>
      file = @getData()

      if /localfile:/.test file.path
        @openSaveDialog()
      else
        file.once 'fs.save.started',    @ace.bound 'saveStarted'
        file.once 'fs.save.finished',   @ace.bound 'saveFinished'
        file.emit 'file.requests.save', contents

    @ace.on 'FileContentChanged', =>
      @ace.contentChanged = @ace.isCurrentContentChanged()

      return  unless @ace.contentChanged

      @setActiveTabHandleClass 'modified'
      @getDelegate().quitOptions =
        message : 'You have unsaved changes. You will lose them if you close this tab.'
        title   : 'Do you want to close this tab?'

    @ace.on 'RemoveModifiedFromTab', @bound 'removeModifiedFromTab'

    @ace.on 'FileContentRestored', =>
      @ace.contentChanged = no
      @ace.removeModifiedFromTab()
      delete @getDelegate().quitOptions

    @on 'KDObjectWillBeDestroyed', =>
      @getDelegate().removeOpenDocument? this

    @ace.on 'ace.changeSetting', (setting, value) ->
      if setting is 'syntax'
        file = @getData()
        fileExtension = file.getExtension()
        appStorage = kd.getSingleton('appStorageController').storage 'Ace', '1.0.1'
        appStorage.setValue "syntax_#{fileExtension}", value

    @ace.on 'FileIsReadOnly', =>
      @setActiveTabHandleClass 'readonly'
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
            cssClass    : 'solid red medium'
            callback    : =>
              @ace.setReadOnly no
              modal.destroy()
          'Cancel'      :
            cssClass    : 'solid light-gray medium'
            callback    : ->
              modal.destroy()


  setActiveTabHandleClass: (cssClass) ->

    { tabView } = @getDelegate()

    return  unless tabView

    activePane = tabView.getActivePane()

    IDEEditorPane = require 'ide/workspace/panes/ideeditorpane'

    return  unless activePane.view instanceof IDEEditorPane

    activePane.tabHandle.setClass cssClass


  toggleFullscreen: ->
    mainView = kd.getSingleton 'mainView'
    mainView.toggleFullscreen()

  getAdvancedSettingsMenuItems: ->
    settings      :
      type        : 'customView'
      view        : new AceSettingsView
        delegate  : @ace

  openSaveDialog: ->

    file      = @getData()
    container = kd.singletons.mainView

    showSaveDialog container, (input, finderController, dialog) =>

      [node] = finderController.treeController.selectedNodes
      name   = Encoder.XSSEncode input.getValue()

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

        { tabView } = @getDelegate()
        return  if not tabView or tabView.willClose

        @getDelegate().openSavedFile newFile, contents

    , { inputDefaultValue: file.name, machine: file.machine }

  _windowDidResize: ->
    @ace?.editor?.resize()

  viewAppended: ->
    super

    @_windowDidResize()

  pistachio: ->
    hasBottomBar = @getOption 'createBottomBar'
    template     = '''
      <div class="kdview editor-main">
        {{> @ace}}
        {{> @findAndReplaceView}}
      </div>
    '''

    if hasBottomBar
      template = '''
        <div class="kdview editor-main">
          {{> @ace}}
          <div class="editor-bottom-bar clearfix">
            {{> @caretPosition}}
            {{> @advancedSettings}}
          </div>
          {{> @findAndReplaceView}}
        </div>
      '''

    return template
