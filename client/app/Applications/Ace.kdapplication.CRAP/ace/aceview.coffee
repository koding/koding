class AceView extends KDView  
  constructor:(options, @file)->
    super
    @setStorage options.storage if options.storage
    @listenWindowResize()

    @registerListener 
      KDEventTypes : 'viewAppended'
      listener     : @
      callback     : @doResize
  
  setStorage: (storage)-> @storage = storage
  
  destroy: ->
    for editor in @getSplitableEditors()
      editor.file.unLock @
      editor.file.revertToSavedState()
      
  closeActiveCodeField: ->
    docManager.removeOpenDocument @getActiveFile()
    @getActiveCodeField().close()
    @propagateEvent { KDEventType : 'StartTabSplittedViewStarted', globalEvent : yes } unless @getSplitableEditors().length
    
  openFileByActiveView: (file) ->
    @emit 'before.change.file'
    file.fetchContents =>
      @getActiveCodeField().openFile {file, loadContent: yes}
      @emit 'after.change.file'
  
  highlight: ->
    handle = @tab.parent
    
    times = 0
    unsetSet = (cb) ->
      handle.setClass 'inactive'
      setTimeout ->
        handle.unsetClass 'inactive'
        setTimeout ->
          times++
          if times <= 2
            unsetSet()
        , 100
      , 80
    
    unsetSet()
  
  close: (callback) ->
    editors = @getSplitableEditors()
    
    filesToSave = []
    
    for editor in editors
      if editor.file.isModified() and editor.file not in filesToSave
        filesToSave.push editor.file
        
    if filesToSave.length
      modal = new KDModalView
        title   : "You have #{filesToSave.length} unsaved file#{if filesToSave.length > 1 then 's' else ''}"
        content : "<div class='modalformline'>Do you want to save them?</div>"
        overlay : yes
        cssClass : "new-kdmodal"
        fx : yes
        width : 400
        height : "auto"
        buttons :
          Yes     :
            style     : "modal-clean-gray"
            callback  : ()->
              modal.destroy()
              callback 'save'
          No:
            style     : "modal-cancel"
            callback  : ()->
              modal.destroy()
              callback 'close'
    else
      callback 'close'
  
  _message: (title, content) ->
    modal = new KDModalView
      title   : title
      content : content
      overlay : no
      cssClass : "new-kdmodal"
      fx : yes
      width : 500
      height : "auto"
      buttons :
        Okay     :
          style     : "modal-clean-gray"
          callback  : ()->
            modal.destroy()
  
  saveDialog: (callback) ->
    self = @
    @addSubView saveDialog = new KDDialogView
      duration      : 200
      topOffset     : 0
      overlay       : yes
      height        : "auto"
      buttons       :
        Save :
          style     : "modal-clean-gray"
          callback  : ()=>
            [node] = @finderController.treeController.selectedNodes
            name   = @inputFileName.inputGetValue()
            
            if name is '' or /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test(name) is false
              @_message 'Wrong file name', "Please type valid file name"
              return
            
            if node.getData().type is ('folder' or 'mount')
              saveDialog.hide()
              callback? name, node.path
            else
              @_message "Wrong selection", "<div class='modalformline'>In order to save file please select one single folder</div>"
        Cancel :
          style     : "modal-cancel"
          callback  : ()->
            saveDialog.hide()

    saveDialog.addSubView wrapper = new KDView cssClass : "kddialog-wrapper"

    wrapper.addSubView header     = new KDHeaderView type : "medium", title : "Save file as:"
    wrapper.addSubView form       = new KDFormView()

    form.addSubView labelFileName = new KDLabelView title : "Filename:"
    form.addSubView @inputFileName = inputFileName = new KDInputView label : labelFileName, defaultValue : @getActiveFile().path.split('/').pop()
    form.addSubView labelFinder   = new KDLabelView title : "Select a folder:"

    # saveDialog.createButton "Save", style : "cupid-green", callback : form.handleEvent({type : "submit"})
    saveDialog.show()
    inputFileName.inputSetFocus()

    @finderController = new NFinderController
      treeItemClass     : NFinderItem 
      nodeIdPath        : "path"
      nodeParentIdPath  : "parentPath"
      dragdrop          : yes
      foldersOnly       : yes
    finder = @finderController.getView()

    form.addSubView finderWrapper = new KDScrollView cssClass : "save-as-dialog file-container",null
    finderWrapper.addSubView finder
    finderWrapper.$().css "max-height" : "200px"

    # by SINAN for FINDER refactoring
    # account = @getSingleton('mainController').getVisitor().currentDelegate
    # account.getDefaultEnvironment (defaultEnvironment, err)=>
    #   if err then log err
    #   else
    #     @finderController.setEnvironment defaultEnvironment

  getName:()->
    @getActiveFile()?.name || 'untitled'

  _windowDidResize:()=>
    @doResize()

  doResize: ->
    if @editorView?.parentIsInDom and @header?.parentIsInDom
      @editorView.setHeight @$().height() - @header.getHeight()

  viewAppended: ->
    super
    
    @header = new Editor_HeaderView delegate : @, null
    @headerButtons = new Editor_HeaderButtons @headerButtonsOptions()
    @header.addSubView @headerButtons
    @addSubView @header

    @openFile @file

  headerButtonsOptions: ->
    cssClass : "header-buttons"
    delegate : @

  saveActiveTabContents:()->
    @handleEvent type : "RequestFileSave"
    
  getEditor: (file) ->
    unless @editorView
      pullContentAfterOpening = no
      delegate                = @
      @addSubView @editorView = new Editor {delegate,pullContentAfterOpening},{file,@fileItem,@pageEditor}
      @editorView.setClass "editor-tab"
      @decorateHeader()

      @setEditorListeners @editorView
      
    @editorView
    
  openFileByDrop: (file, editor) ->
    editor.focus()
    @openFileByActiveView file

  openFile:(file)->
    @file = file
    editor = @getEditor file
    
    @emit 'before.change.file'
    
    file.fetchContents (c) =>
      editor.splittable.getEditors()[0].openFile {file, loadContent : yes}
      @emit 'after.change.file'
      
  setEditorListeners: ->
    return if @_editorListenersAreOn
    @_editorListenersAreOn = yes
      
    notify = () =>
      @notifySavedState()
      
    subscribeChange = =>
      @getActiveFile().on 'change', notify
    unsubscribeChange = =>
      @getActiveFile().unsubscribe 'change', notify
      
    @on 'before.change.file', =>
      for editor in @getSplitableEditors()
        editor.file.unLock @
        
      unsubscribeChange()
      
    @on 'after.change.file', =>
      subscribeChange()
      notify()
      for editor in @getSplitableEditors()
        editor.file.lock @, 'File is in use by Ace editor'
      
    @listenTo
      KDEventTypes        : 'EditorCodeViewInFocus'
      listenedToInstance  : @editorView
      callback            : (pubInst, event) =>
        unsubscribeChange()
        
        @_activeFile        = event.codeField.file
        @_activeCodeField   = event.codeField

        @propagateEvent { KDEventType: 'EditorIsReadyForSplits' }
        
        subscribeChange()
        notify()
        # @handleEvent type: 'DocumentChangedFocusToAnotherFile', file: event.codeField.file
        
  getActiveCodeField: ->
    @_activeCodeField
        
  getActiveFile: ->
    if @_activeCodeField
      @_activeCodeField.file
    else
      @file

  getSplitableEditors: ->
    if @getEditorView()
      @getEditorView().splittable.getEditors()
    else
      #there is no view, and there are no splitables
      []
    
  getEditorView: ->
    @editorView

  notifySavedState:()->
    @propagateEvent KDEventType : 'NotifyUnsavedState', globalEvent : yes, file: @getActiveFile()

  decorateHeader:()->
    if @saveInterval?
      @handleEvent type : "AutoSaveStateDidChange", state : on
    else
      @handleEvent type : "AutoSaveStateDidChange", state : off

  setAutoSave:()->
    @_autoSave = on
    unless @saveInterval?
      @saveInterval = setInterval ()=>
        for editor in @getSplitableEditors()
          unless editor.file.isNew()
            # log editor.file
            @emit 'request.file.save', @, editor.file, {autosave: yes}
      , 30000

  unsetAutoSave:()->
    @_autoSave = off
    if @saveInterval?
      clearInterval @saveInterval
      @saveInterval = null

  getAutoSave: ->
    @_autoSave
