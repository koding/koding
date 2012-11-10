###
  todo:

    - make save dialog a view with pistachio
    - put listeners in methods
    - make this splittable

###

class AceView extends JView

  constructor:(options, file)->

    super

    @listenWindowResize()

    @saveButton = new KDButtonViewWithMenu
      title         : "Save"
      style         : "editor-button save-menu"
      type          : "contextmenu"
      delegate      : @
      menu          : @getSaveMenu.bind @
      callback      : ()=>
        @ace.requestSave()

    @caretPosition = new KDCustomHTMLView
      tagName       : "div"
      cssClass      : "caret-position section"
      partial       : "<span>1</span>:<span>1</span>"

    @ace = new Ace {}, file

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

    publicUrlCheck = /.*\/(.*\.koding.com)\/website\/(.*)/
    @previewButton = new KDButtonView
      style     : "editor-button"
      icon      : yes
      iconOnly  : yes
      iconClass : "preview"
      callback  : =>
        publicPath = @getData().path.replace publicUrlCheck, 'http://$1/$2'
        return if publicPath is @getData().path
        appManager.openFileWithApplication publicPath, "Viewer"

    @previewButton.hide() unless publicUrlCheck.test(@getData().path)

    @compileAndRunButton = new KDButtonView
      style     : "editor-button"
      title     : "Compile & Run"
      loader    :
        color   : "#444444"
        diameter: 12
      callback  : =>
        manifest = KodingAppsController.getManifestFromPath @getData().path
        @ace.notify "Compiling...", null, yes
        @getSingleton('kodingAppsController').compileApp manifest.name, =>
          @ace.notify "App compiled!", "success"
          @getSingleton('kodingAppsController').runApp manifest
          @compileAndRunButton.hideLoader()

    @compileAndRunButton.hide() unless /\.kdapp\//.test @getData().path

    @setViewListeners()

  setViewListeners:->

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

  viewAppended:->

    super
    @_windowDidResize()

  pistachio:->

    """
    <div class="kdview editor-header">
      <div class="kdview header-buttons">
        {{> @compileAndRunButton}}
        {{> @previewButton}}
        {{> @saveButton}}
      </div>
    </div>
    <div class="kdview editor-main">
      {{> @ace}}
      <div class="editor-bottom-bar clearfix">
        {{> @caretPosition}}
        {{> @advancedSettings}}
      </div>
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

    height = @getHeight() - 10
    editorHeight = height - @$('.editor-header').height()
    bottomBarHeight = @$('.editor-bottom-bar').height()
    @$('.editor-main').height editorHeight
    @ace.setHeight editorHeight - bottomBarHeight

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
          callback  : ()=>
            [node] = @finderController.treeController.selectedNodes
            name   = @inputFileName.getValue()

            if name is '' or /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test(name) is false
              @_message 'Wrong file name', "Please type valid file name"
              @ace.notify "Please type valid file name!", "error"
              return

            unless node
              @ace.notify "Please select a folder to save!", "error"
              return

            parent = node.getData()
            file.emit "file.requests.saveAs", @ace.getContents(), name, parent.path
            saveDialog.hide()
        Cancel :
          style     : "modal-cancel"
          callback  : ()->
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
      treeItemClass     : NFinderItem
      nodeIdPath        : "path"
      nodeParentIdPath  : "parentPath"
      dragdrop          : yes
      foldersOnly       : yes
      contextMenu       : no

    finder = @finderController.getView()

    form.addSubView finderWrapper = new KDView cssClass : "save-as-dialog file-container",null
    finderWrapper.addSubView finder
    finderWrapper.setHeight 200
