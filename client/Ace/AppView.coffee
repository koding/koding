###
  todo:

    - make save dialog a view with pistachio
    - put listeners in methods
    - make this splittable

###

class AceView extends JView

  constructor:(options = {}, file)->

    options.advancedSettings ?= no

    super options, file

    @listenWindowResize()

    @caretPosition = new KDCustomHTMLView
      tagName       : "div"
      cssClass      : "caret-position section"
      partial       : "<span>1</span>:<span>1</span>"

    @ace = new Ace
      delegate        : @
      enableShortcuts : yes
    , file

    @advancedSettings = new KDButtonViewWithMenu
      style         : 'editor-advanced-settings-menu'
      icon          : yes
      iconOnly      : yes
      iconClass     : "cog"
      type          : "contextmenu"
      delegate      : this
      itemClass     : AceSettingsView
      click         : (pubInst, event)-> @contextMenu event
      menu          : @getAdvancedSettingsMenuItems.bind @
    @advancedSettings.disable()

    unless options.advancedSettings
      @advancedSettings.hide()

    @findAndReplaceView = new AceFindAndReplaceView delegate: @
    @findAndReplaceView.hide()

    @setViewListeners()

  setViewListeners:->

    @ace.on "ace.ready", => @advancedSettings.enable()

    @ace.on "ace.changeSetting", (setting, value)=>
      @ace["set#{setting.capitalize()}"]? value

    @advancedSettings.emit "ace.settingsView.setDefaults", @ace

    $spans = @caretPosition.$('span')

    @ace.on "ace.change.cursor", (cursor)=>
      $spans.eq(0).text ++cursor.row
      $spans.eq(1).text ++cursor.column

    @ace.on "ace.requests.saveAs", (contents, options)=>
      @openSaveDialog options

    @ace.on "ace.requests.save", (contents)=>
      file = @getData()
      if /localfile:/.test file.path
        @openSaveDialog closeAfter: no
      else
        file.once "fs.save.started",    @ace.bound "saveStarted"
        file.once "fs.save.finished",   @ace.bound "saveFinished"
        file.emit "file.requests.save", contents

    @ace.on "FileContentChanged", =>
      @ace.contentChanged = yes
      @getActiveTabHandle().setClass "modified"
      @getDelegate().quitOptions =
        message : "You have unsaved changes. You will lose them if you close this tab."
        title   : "Do you want to close this tab?"

    @ace.on "FileContentSynced", =>
      @ace.contentChanged = no
      @getActiveTabHandle().unsetClass "modified"
      delete @getDelegate().quitOptions

    @on 'KDObjectWillBeDestroyed', =>
      file = @getData()
      KD.singletons.localSync.removeFromOpenedFiles file
      @getDelegate().removeOpenDocument @

    @ace.on "ace.changeSetting", (setting, value)->
      if setting is "syntax"
        file = @getData()
        fileExtension = file.getExtension()
        appStorage = KD.getSingleton('appStorageController').storage 'Ace', '1.0.1'
        appStorage.setValue "syntax_#{fileExtension}", value

    @ace.on "FileIsReadOnly", =>
      @getActiveTabHandle().setClass "readonly"
      @ace.setReadOnly yes
      modal             = new KDModalView
        title           : "This file is readonly"
        content         : """
        <div class="modalformline">
          <p>
            The file <code>#{@getData().name}</code> is set to readonly,
            you won't be able to save your changes.
          </p>
        </div>
        """
        buttons         :
          "Edit Anyway" :
            cssClass    : "modal-clean-red"
            callback    : =>
              @ace.setReadOnly no
              modal.destroy()
          "Cancel"      :
            cssClass    : "modal-cancel"
            callback    : ->
              modal.destroy()

  getActiveTabHandle: ->
    return  @getDelegate().tabView.getActivePane().tabHandle

  toggleFullscreen: ->
    mainView = KD.getSingleton "mainView"
    mainView.toggleFullscreen()

  viewAppended:->

    super
    @_windowDidResize()

  pistachio:->

    """
    <div class="kdview editor-main">
      {{> @ace}}
      <div class="editor-bottom-bar clearfix">
        {{> @caretPosition}}
        {{> @advancedSettings}}
      </div>
      {{> @findAndReplaceView}}
    </div>
    """

  getAdvancedSettingsMenuItems:->

    settings      :
      type        : 'customView'
      view        : new AceSettingsView
        delegate  : @ace

  getSaveMenu:->

    "Save as..." :
      id         : 13
      parentId   : null
      callback   : =>
        @openSaveDialog closeAfter: no

  _windowDidResize:->

    height = @getHeight()
    bottomBarHeight = @$('.editor-bottom-bar').height()
    newHeight = height - bottomBarHeight
    @ace.setHeight newHeight unless newHeight is 0

  openSaveDialog: (options = {}) ->
    { closeAfter }   = options

    file = @getData()
    KD.utils.showSaveDialog this, (input, finderController, dialog) =>
      [node] = finderController.treeController.selectedNodes
      name   = input.getValue()

      return @ace.notify "Please type valid file name!"   , "error"  unless FSHelper.isValidFileName name
      return @ace.notify "Please select a folder to save!", "error"  unless node

      dialog.destroy()
      # @utils.wait 300, => # temp fix to be sure overlay has removed with fade out animation

      parent = node.getData()
      file.emit "file.requests.saveAs", @ace.getContents(), name, parent.path
      file.once "fs.saveAs.finished",   @ace.bound "saveAsFinished"
      @ace.emit "AceDidSaveAs", name, parent.path
      oldCursorPosition = @ace.editor.getCursorPosition()
      file.on "fs.saveAs.finished", =>
        {tabView} = @getDelegate()
        return  if tabView.willClose
        @getDelegate().openFile \
          FSHelper.createFileInstance path: "#{parent.path}/#{name}"

        if closeAfter
          @utils.defer =>
            tabView.removePane_ tabView.getActivePane()
            {ace} = tabView.getActivePane().getOptions().aceView
            ace.on "ace.ready", ->
              ace.editor.moveCursorTo oldCursorPosition.row, oldCursorPosition.column

    , { inputDefaultValue: file.name }
