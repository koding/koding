class DocumentController extends KDViewController
  constructor:(options={},data)->
    options.view or= documentView = new DocumentView name:data.name
    super options,data
    
    documentView.registerListener KDEventTypes:"DocumentMovedBack", listener:@, callback:@documentMovedBack
    documentView.registerListener KDEventTypes:'KDViewBecameKeyView', listener:@, callback:@setDocumentFocus
    documentView.registerListener KDEventTypes:'AdvancedSettingClick', listener:@, callback:@createSettingsMenu
    documentView.registerListener KDEventTypes:'DocumentSaveClick', listener:@, callback:@saveDocument
    documentView.registerListener KDEventTypes:'DocumentSaveAsClick', listener:@, callback:@saveAsDocument
  
  documentMovedBack:(publishingInstance, {autoCreated})->
    if autoCreated and not @getData().isModified()
      @getView().propagateEvent KDEventType:"ViewClosed"
  
  setDocumentFocus:->
    @codeMirror.focus()
  
  loadView:(documentView)->
    controller = @
    options = $.extend {}, storage.bucket.appOptions.visualPreferences, storage.bucket.appOptions.textPreferences, storage.bucket.extensionOptions?[@getData().getExtension()]?.visualPreferences
    
    async.parallel [
      @getData().getContents.bind @getData()
    , (callback)->controller.loadOptionDependencies options, callback
    ], (contents)->
      $.extend options, value: contents, onCursorActivity : controller.cursorPositionChanged
      controller.codeMirror = codeMirror = CodeMirror documentView.$('.code-mirror-wrapper')[0], options
      (controller.getSingleton 'windowController').setKeyView documentView
      
  destroy:()->
    delete @getDelegate().documentControllersByFileId[@getData().getId()]
    super
  
  cursorPositionChanged:=>
    {line, ch} = @codeMirror.getCursor()
    @getView().getBottomBar().updateCursorPosition line, ch
  
  createSettingsMenu:(pubInst,button)->
    controller = @
    codeMirror = @codeMirror
    
    items = [
        { title : 'Indent With Tabs',              id : 1,  parentId : null, type : 'switch'      ,optionSource : 'bucket.appOptions.textPreferences'              ,editorOption : 'indentWithTabs' }
        { title : 'Use Smart Indent',              id : 2,  parentId : null, type : 'switch'      ,optionSource : 'bucket.appOptions.textPreferences'              ,editorOption : 'smartIndent' }
        { title : 'Tab Size'        ,              id : 3,  parentId : null, type : 'input'       ,optionSource : 'bucket.appOptions.textPreferences'              ,editorOption : 'tabSize' }
        { title : 'Line Wrapping'   ,              id : 4,  parentId : null, type : 'switch'      ,optionSource : 'bucket.appOptions.visualPreferences'            ,editorOption : 'lineWrapping' }
        { title : 'Line Numbers'    ,              id : 5,  parentId : null, type : 'switch'      ,optionSource : 'bucket.appOptions.visualPreferences'            ,editorOption : 'lineNumbers' }
        { title : 'Match Brackets'  ,              id : 6,  parentId : null, type : 'switch'      ,optionSource : 'bucket.appOptions.visualPreferences'            ,editorOption : 'matchBrackets' }
        { type  : 'divider' }
        { title : 'Mode'            ,              id : 7,  parentId : null, type : 'select'      ,optionSource : "bucket.extensionOptions.#{@getData().getExtension()}.visualPreferences"      ,editorOption : 'mode' }
        { title : 'Theme'           ,              id : 8,  parentId : null, type : 'select'      ,optionSource : 'bucket.appOptions.visualPreferences'            ,editorOption : 'theme' }
    ]
    # menu.items.push title: 'Tab size',             id : 11, parentId : null, type : 'element',   default: (-> editor.getTabSize()),              element: new Editor_BottomBar_TabSizeSelector  (delegate: @getDelegate())
    # menu.items.push title: '⌘ Keyboard Shortcuts',   id : 13, parentId : null, type : 'keyboard',  function : "showKeyboardHelper"
    
    items.forEach (item)->
      values = null
      item.default = ->
        values = JsPath.getAt storage, item.optionSource
        unless values? then values = JsPath.getAt storage, item.optionSource.replace /extensionOptions\..*\./, 'appOptions.'
        values[item.editorOption]
      item.callback = (value) ->
        if values[item.editorOption] isnt value
          JsPath.setAt storage, "#{item.optionSource}.#{item.editorOption}", value
          storage.save (err)->if err then console.warn err
        controller.setEditorOption.call controller, item.editorOption, value
    
    menu = {
      type  : "contextmenu"
      items
    }

    buttonMenu = new PersistingButtonMenu
      cssClass : "editor-advanced-settings-menu"
      # ghost    : @$('.chevron-arrow').clone()
      # event    : event
      delegate : button

    buttonMenu.addSubView menuTree = new KDContextMenuTreeView delegate : @
    new EditorAdvancedSettings_ContextMenu view : menuTree, menu

    KDView.appendToDOMBody buttonMenu
    buttonMenu.viewAppended()
  
  setEditorOption:(option, value)->
    controller = @
    
    options = {}
    options[option] = value
    @loadOptionDependencies options, ->
      controller.codeMirror.setOption option, value
  
  loadOptionDependencies:(options,callback)->
    requirePaths =
      js : []
      css : []
    
    if (value = options.mode)?
      requirePaths.js = ["js/KDApplications/CodeMirror.kdapplication/mode/#{value}/#{value}.js"] unless value is 'text/plain'
      if (dependencies = modeDependencies[value])?
        requirePaths.js.push "js/KDApplications/CodeMirror.kdapplication/mode/#{dependency}/#{dependency}.js" for dependency in dependencies.javascript
        if dependencies.css?
          requirePaths.css.push "text!KDApplications/CodeMirror.kdapplication/mode/#{dependency}/#{dependency}.css" for dependency in dependencies.css
      
    if (value = options.theme)?
      requirePaths.css.push "text!KDApplications/CodeMirror.kdapplication/theme/#{value}.css"

    requirejs (requirePaths.js.concat requirePaths.css), ->
      args = Array.prototype.slice.call arguments
      for cssText in args[requirePaths.js.length..]
        $("<style type='text/css'>#{cssText}</style>").appendTo("head")
      callback()
  
  saveDocument:->
    file = @getData()
    if file.isNew()
      @saveAsDocument()
    else
      file.setContents @codeMirror.getValue()
      if file.isModified()
        file.save ({error}) =>
          @processSavedFile error, file
      else
        new KDNotificationView
          title     : "Nothing to save"
          duration  : 1000
          type      : 'growl'
  
  saveAsDocument:->
    controller = @
    oldFile = @getData()
    saveDialogController = new SaveDialogController file:oldFile, callback : (name, parentPath)->
      if (isNewFile = oldFile.isNew())
        file = oldFile
        file.setContents controller.codeMirror.getValue()
        file.name = name
        file.path = "#{parentPath}/#{name}"
        fs.register file
      else
        file = fs.create path: "#{parentPath}/#{name}", name: name, contents: controller.codeMirror.getValue()

      file.save ({error}) =>
        controller.processSavedFile error, file
        unless error
          unless isNewFile
            oldFile.revertToSavedState()
            controller.codeMirror.setValue oldFile.contents
            controller.getDelegate().openFile file
          # documentView.openFileByActiveView file
    
    @getView().addSubView saveDialogController.getView()
            
  processSavedFile: (error, file) ->
    if error
      new KDNotificationView
        title : "Error, #{error}, while trying to save #{file.name}"
        duration : 2500
    else
      new KDNotificationView
        title : "#{file.name} saved!"
        duration : 500
        type: if @getOptions().autosave then 'growl' else null
