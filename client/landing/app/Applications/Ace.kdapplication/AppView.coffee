###
  todo:

    - make save dialog a view with pistachio
    - put listeners in methods
    - make this splittable

###

class AceView extends JView

  constructor:(options = {}, file)->

    options.advancedSettings ?= yes

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
      delegate      : @
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

    @ace.on "ace.requests.saveAs", (contents)=>
      @openSaveDialog()

    @ace.on "ace.requests.save", (contents)=>
      if /localfile:/.test @getData().path
        @openSaveDialog()
      else
        @getData().emit "file.requests.save", contents

    @ace.on "FileContentChanged", =>
      @getActiveTabHandle().setClass "modified"
      @getDelegate().quitOptions =
        message : "You have unsaved changes. You will lose them if you close this tab."
        title   : "Do you want to close this tab?"

    @ace.on "FileContentSynced", =>
      @getActiveTabHandle().unsetClass "modified"
      delete @getDelegate().quitOptions

  getActiveTabHandle: ->
    return  @getDelegate().tabView.getActivePane().tabHandle

  preview: ->
    {vmName, path} = @getData()
    KD.getSingleton("appManager").open "Viewer", params: {path, vmName}

  compileAndRun: ->
    manifest = KodingAppsController.getManifestFromPath @getData().path
    return @ace.notify "Not found an app to compile", null, yes unless manifest?.name
    KD.getSingleton('kodingAppsController').compileApp manifest.name, (err) =>
      @ace.notify "Trying to run old version..." if err
      KD.getSingleton('appManager').open manifest.name

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
        @openSaveDialog()

  _windowDidResize:->

    height = @getHeight()
    bottomBarHeight = @$('.editor-bottom-bar').height()
    @ace.setHeight height - bottomBarHeight

  openSaveDialog: (callback) ->

    file = @getData()
    @addSubView saveDialog = new KDDialogView
      cssClass      : "save-as-dialog"
      duration      : 200
      topOffset     : 0
      overlay       : yes
      height        : "auto"
      buttons       :
        Save        :
          style     : "modal-clean-gray"
          callback  : =>
            [node] = @finderController.treeController.selectedNodes
            name   = @inputFileName.getValue()

            if name is '' or /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test(name) is false
              @ace.notify "Please type valid file name!", "error"
              return

            unless node
              @ace.notify "Please select a folder to save!", "error"
              return

            parent = node.getData()
            file.emit "file.requests.saveAs", @ace.getContents(), name, parent.path
            saveDialog.hide()
            @ace.emit "AceDidSaveAs", name, parent.path
            oldCursorPosition = @ace.editor.getCursorPosition()
            file.on "fs.saveAs.finished", =>
              {tabView} = @getDelegate()
              @getDelegate().openFile FSHelper.createFileFromPath "#{parent.path}/#{name}", yes
              @utils.defer =>
                newIndex = tabView.getPaneIndex tabView.getActivePane()
                tabView.removePane tabView.getPaneByIndex newIndex - 1
                {ace} = tabView.getActivePane().getOptions().aceView
                ace.on "ace.ready", =>
                  ace.editor.moveCursorTo oldCursorPosition.row, oldCursorPosition.column

        Cancel      :
          style     : "modal-cancel"
          callback  : =>
            @finderController.stopAllWatchers()
            delete @finderController
            saveDialog.hide()

    saveDialog.addSubView wrapper = new KDView
      cssClass : "kddialog-wrapper"

    wrapper.addSubView form = new KDFormView

    form.addSubView labelFileName = new KDLabelView
      title : "Filename:"

    form.addSubView @inputFileName = inputFileName = new KDInputView
      label        : labelFileName
      defaultValue : file.name

    form.addSubView labelFinder = new KDLabelView
      title : "Select a folder:"

    saveDialog.show()
    inputFileName.setFocus()

    @finderController = new NFinderController
      nodeIdPath        : "path"
      nodeParentIdPath  : "parentPath"
      foldersOnly       : yes
      contextMenu       : no
      loadFilesOnInit   : yes

    finder = @finderController.getView()
    @finderController.reset()

    form.addSubView finderWrapper = new KDView cssClass : "save-as-dialog file-container",null
    finderWrapper.addSubView finder
    finderWrapper.setHeight 200
