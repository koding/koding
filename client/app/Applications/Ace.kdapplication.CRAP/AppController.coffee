class Ace12345 extends AppController
  setStorage:(@_storage)->
    @propagateEvent KDEventType : 'storage.ready', @_storage
  
  getStorage:(callback)->
    if @_storage
      callback @_storage
    else
      @registerListenOncer
        KDEventTypes : 'storage.ready'
        listener : @
        callback : (pubInst, storage)->
          callback storage

  initApplication:(options, callback)=>
    @openDocuments  = []
    @_storage       = no
    # console.log 'init application called'
    notification = no
    timeout = setTimeout ->
      notification = new KDNotificationView
        title   : "Still loading editor..."
        type    : 'tray'
        duration: 0
    , 2000

    require ['ace/ace'],(text, aceUncompressed)=>
      clearTimeout timeout
      if notification
        notification.destroy()
        
      @getStorage (storage) =>

        @propagateEvent
          KDEventType : 'ApplicationInitialized', globalEvent : yes
        
        callback()

  initAndBringToFront:(options, callback)=>
    @initApplication options, =>
      @bringToFront()
      callback()

  bringToFront:(frontDocument)=>
    unless frontDocument
      if @doesOpenDocumentsExist()
        frontDocument = @getFrontDocument()
      else
        frontDocument = @createNewDocument()
        @autoCreatedDocument = frontDocument

    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle  : no
        type          : 'application'
        name          : frontDocument.getName()
        tabHandleView : frontDocument.tab or= new AceTabHandleView
        controller    : @
      data : frontDocument

  doesOpenDocumentsExist:()->
    if @openDocuments.length > 0 then yes else no

  getOpenDocuments:()->
    @openDocuments

  getFrontDocument:()->  
    [backDocuments...,frontDocument] = @getOpenDocuments()
    frontDocument
  
  addOpenDocument:(document)->
    appManager.addOpenTab document, @
    @openDocuments.push document
    
  removeOpenDocument:(document)->
    appManager.removeOpenTab document
    @openDocuments.splice (@openDocuments.indexOf document), 1
  
  createNewDocument:(file)->
    appController = @
    unless file?
      file = docManager.getUntitledFile()
      # file = path: '~~~/file/doesnt/exist/Untitled.txt', name: 'Untitled.txt'
    
    document = new AceView {}, file
    @getStorage (storage)->
      if storage
        document.setStorage storage

    appController.addOpenDocument document
  
    document.registerListener KDEventTypes:"viewIsReady", callback:appController.loadDocumentView, listener:appController
    document.on 'request.file.save', appController.saveFile.bind(appController)
    document.on 'request.file.saveas', =>
      appController.saveFileAs document
    document.registerListener KDEventTypes:'NotifyUnsavedState', listener:appController, callback:appController.updateTitle
    document.registerListener KDEventTypes:'RequestFileSave', listener:appController, callback:appController.saveFile
    document.registerListener KDEventTypes:'RequestFileSaveAs', listener:appController, callback:appController.saveFileAs
    # document.registerListener KDEventTypes:'RequestFileHasChanged', listener:appController, callback:appController.fileHasChangedByEditor #from editor
    document.registerListener KDEventTypes:'ViewClosed', listener:appController, callback:appController.closeDocument
    # document.registerListener KDEventTypes:'DocumentChangedFocusToAnotherFile', listener:appController, callback:appController.changedFocusToAnotherFile
    
    # appController.setFileListeners document, file
  
    document
    
    # you can't expect a return value from an async function - sinan 26 April 2012
    # @getStorage (storage)->
    #   document = new AceView {storage}, file
    #   appController.addOpenDocument document
    # 
    #   document.registerListener KDEventTypes:"viewIsReady", callback:appController.loadDocumentView, listener:appController
    #   document.on 'request.file.save', appController.saveFile.bind(appController)
    #   document.on 'request.file.saveas', =>
    #     appController.saveFileAs document
    #   document.registerListener KDEventTypes:'NotifyUnsavedState', listener:appController, callback:appController.updateTitle
    #   document.registerListener KDEventTypes:'RequestFileSave', listener:appController, callback:appController.saveFile
    #   document.registerListener KDEventTypes:'RequestFileSaveAs', listener:appController, callback:appController.saveFileAs
    #   # document.registerListener KDEventTypes:'RequestFileHasChanged', listener:appController, callback:appController.fileHasChangedByEditor #from editor
    #   document.registerListener KDEventTypes:'ViewClosed', listener:appController, callback:appController.closeDocument
    #   # document.registerListener KDEventTypes:'DocumentChangedFocusToAnotherFile', listener:appController, callback:appController.changedFocusToAnotherFile
    #   
    #   # appController.setFileListeners document, file
    # 
    # document
      
  _closeDocument: (document) ->
    document.parent.removeSubView document
    @removeOpenDocument document

    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : document
    # document.setClean()
    # @propagateFileChanges document
    document.destroy()
  
  closeDocument:(document)->
    document.close (operation) =>
      if operation is 'close'
        @_closeDocument document
      else
        @saveAllFiles document
  
  newFile:()->
    @bringToFront @createNewDocument()
    
  getDocumentWhichOwnsThisFile: (file) ->
    for document in @getOpenDocuments()
      if document.file is file
        return document
    null

  #required
  openFile: (file, options = {})=>
    document = @getDocumentWhichOwnsThisFile file
    if document
      @bringToFront document
      document.highlight()
    else
      frontDocument = @getFrontDocument()
      if not frontDocument?.file.isModified() and @autoCreatedDocument is frontDocument
        documentToClose = frontDocument
      document = @createNewDocument file
      @bringToFront document
      if documentToClose?
        @closeDocument documentToClose

  loadDocumentView:(documentView)->
    if (file = documentView.file)? and documentView.editorView?
      documentView.editorView.splittable.getEditors()[0].openFile {file, loadContent : yes}
      documentView.doResize()
      
    @bindShortcuts documentView
    

  bindShortcuts: (documentView) ->
    event     = requirejs('ace/lib/event')
    keyLib    = requirejs('ace/lib/keys')
    useragent = requirejs 'ace/lib/useragent'
    
    manager   = new (requirejs('ace/commands/command_manager').CommandManager)(if useragent.isMac then "mac" else "win")
    
    manager.addCommand
      name: 'close'
      bindKey:
        mac: 'Alt-Shift-Q'
        win: 'Alt-Shift-Q'
        sender: 'editor'
      exec: ->
        # documentView.editorView.getActiveCodeField().close()
        documentView.closeActiveCodeField()
        
    manager.addCommand
      name: 'split'
      bindKey:
        mac: 'Alt-Shift-D'
        win: 'Alt-Shift-D'
        sender: 'editor'
      exec: =>
        # documentView.getActiveCodeField().handleEvent type: 'EditorSplit', splitType: 'vertical'
        documentView.getActiveCodeField().propagateEvent KDEventType: 'EditorSplit', {splitType: 'vertical', direction: 'right'}
        # document.getActiveCodeField().close()
    manager.addCommand
      name: 'splitHorizontal'
      bindKey:
        mac: 'Alt-Shift-C'
        win: 'Alt-Shift-C'
        sender: 'editor'
      exec: =>
        # documentView.getActiveCodeField().handleEvent type: 'EditorSplit', splitType: 'horizontal'
        documentView.getActiveCodeField().propagateEvent KDEventType: 'EditorSplit', {splitType: 'horizontal', direction: 'bottom'}
        
    manager.addCommand
      name: 'find'
      bindKey:
        mac: 'Command-F'
        win: 'Ctrl-F'
        sender: 'editor'
      exec: =>
        # @getEditor().handleEvent type: 'EditorSearchFormShow'
        documentView.editorView.handleEvent type: 'EditorSearchFormShow'
    
    manager.addCommand
      name: 'findnext'
      bindKey:
        mac: 'Command-G'
        win: 'Ctrl-G'
        sender: 'editor'
      exec: =>
        # @getEditor().handleEvent type: 'EditorFind'
        documentView.editorView.handleEvent type: 'EditorFind'
    
    manager.addCommand
      name: 'compileCode'
      bindKey:
        mac: 'Command-B'
        win: 'Ctrl-B'
        sender: 'editor'
      exec: =>
        # @tryToCompile()
        documentView.editorView.tryToCompile()
    
    manager.addCommand
      name: 'compile'
      bindKey:
        mac: 'Command-E'
        win: 'Ctrl-E'
        sender: 'editor'
      exec: =>
        # @getEditor().handleEvent type: 'EditorTryToRun'
        documentView.editorView.handleEvent type: 'EditorTryToRun'
    
    manager.addCommand
      name: 'save'
      bindKey:
        mac: 'Command-S'
        win: 'Ctrl-S'
        sender: 'editor'
      exec: =>
        documentView.emit 'request.file.save', documentView
        # documentView.handleEvent type: 'RequestFileSave'
        
    manager.addCommand
      name: 'saveas'
      bindKey:
        mac: 'Command-Shift-S'
        win: 'Ctrl-Shift-S'
        sender: 'editor'
      exec: =>
        documentView.emit 'request.file.saveas', documentView
        # documentView.handleEvent type: 'RequestFileSaveAs'
    
    manager.addCommand
      name: 'autocomplete'
      bindKey:
        mac: 'Esc'
        win: 'Esc'
        sender: 'Editor'
      exec: =>
        # @getEditor().handleEvent type: 'EditorTryToAutocomplete'
        documentView.editorView.handleEvent type: 'EditorTryToAutocomplete'
    
    manager.addCommand
      name: 'backwardAutocomplete'
      bindKey:
        mac: 'Esc-Shift'
        win: 'Esc-Shift'
        sender: 'Editor'
      exec: =>
        # @getEditor().handleEvent type: 'EditorTryToAutocomplete', backward: yes
        documentView.editorView.handleEvent type: 'EditorTryToAutocomplete', backward: yes
    
    event.addCommandKeyListener documentView.$()[0], (e, hashId, keyCode) ->
      keyString = keyLib.keyCodeToString(keyCode)
      
      command = manager.findKeyCommand hashId, keyString
      if command
        command.exec()
        e.preventDefault()
        e.stopPropagation()
    
  updateTitle: (document) ->
    document.tab.setTitle (if document.getActiveFile().isModified() then '*' else '') + document.getActiveFile().name    
  
  saveFileAs: (documentView, event) ->
    oldFile = documentView.getActiveFile()
    documentView.saveDialog (name, parentPath) =>

      # file = FS.get "#{parentPath}/#{name}"
      file = FSHelper.createFileFromPath "#{parentPath}/#{name}"
      
      # oldFile.contents

      file.save ({error}) =>
        @processSavedFile error, documentView, file
      
        unless error
          oldFile.revertToSavedState()
      # documentView.file = file
          documentView.openFileByActiveView file
      
      
  saveAllFiles: (documentView) ->
    for editor in documentView.getSplitableEditors()
      @saveFile documentView, editor.file
    
      
  saveFile: (documentView, file, options = {}) ->
    file = documentView.getActiveFile() unless file?.isNew? #hack to see if we have a file here... 2/8/12-sah
    if file.isNew()
      @saveFileAs documentView
    else
      if file.isModified()
        file.save ({error}) =>
          @processSavedFile error, documentView, file, options
      else
        unless options.autosave
          new KDNotificationView
            title     : "Nothing to save"
            duration  : 1000
            type      : 'growl'
            
  processSavedFile: (error, documentView, file, options = {}) ->
    if error
      new KDNotificationView
        title : "Something wrong, couldn't save #{file.name}"
        duration : 2500
    else
      new KDNotificationView
        title : "#{file.name} saved!"
        duration : 500
        type: if options.autosave then 'growl' else null

  getDocumentContents:(documentView)->
    file = documentView.file
    for editor in documentView.editorView.splittable.getEditors()
      if file is editor.file
        # log 'returning new value', editor.editor.getSession().getValue()
        return editor.editor.getSession().getValue()
    ''
    # documentView.editorView.splittable.getEditors()[0].editor.getSession().getValue()

  openFileByDrop: (editor, file) ->
    # console.log '@', @, file
    if @pageEditor.getSplitableEditors().length is 1
      superController = @getSuperController() 
      superController.setIdByFile file
      # console.log 'super', superController

    editor.openFile file: file, loadContent: yes

  setCursor: (pos) ->
    # console.log 'set cursor and column', pos,  @pageEditor.getSplitableEditors()
    @pageEditor.getSplitableEditors()[0].setCursor pos

  @getName: ->
    'ace'

  @getExtensions: ->
    data = __aceData
    extensions = []
    for name, list of data.syntaxExtensionAssociations
      for ext in list
        extensions.push ext

    extensions

  createFreshSplit:(splitData)->
    document = @createNewDocument()
    document.registerListenOncer 
      KDEventTypes  : "EditorIsReadyForSplits"
      listener      : @
      callback      : ->
        document.getActiveCodeField().propagateEvent KDEventType: 'EditorSplit', splitData
    @bringToFront document

