class SplittableCodeField extends KDView
  constructor: ->
    super
    @_editors = []
    @_splits  = []

  viewAppended: ->

  getActiveCodeField: ->
    @_activeCodeField

  setEventListeners: (editor, options) ->
    @listenTo
      KDEventTypes: 'EditorCodeViewInFocus'
      listenedToInstance: editor
      callback: (pubInst) =>
        @_activeCodeField = pubInst
        @handleEvent type: 'EditorCodeViewInFocus', codeField: pubInst

    @listenTo
      KDEventTypes: 
        eventType: 'EditorSplit'
      listenedToInstance: editor
      callback: (pubInst, event) =>
        if event.splittingFromStartTab?
          @createSplitViewFromStartTab pubInst, event, editor, options
        else 
          @createSplitViewFromAceEditor pubInst, event, editor, options

  createSplitViewFromAceEditor:(pubInst, event, editor, options)->
    parent      =  editor.parent
    placeholder =  @createPlaceholder editor, options

    #remove editor from subViews of parent view
    # index       =  editor.parent.subViews.indexOf editor
    # if index > -1
    #   editor.parent.subViews.splice index, 1
    
    if event.direction is 'right' or event.direction is 'bottom'
      viewsArray = [editor, placeholder]
    else
      viewsArray = [placeholder, editor]

    parent.addSubView newSplit = new EditorSplitView 
      views: viewsArray
      sizes: ['50%', '50%']
      type: event.splitType

    # @registerSplit newSplit
    
  createSplitViewFromStartTab:(pubInst, event, editor, options)->
    docManager.removeOpenDocument editor.file
    
    parent      =  editor.parent
    options.fromStart = yes
    individualSplits = []
    
    createSplit = (splits)=>
      if arguments.length is 0
        firstPane = @createPlaceholder editor, options
        secondPane = @createPlaceholder editor, options
      else
        [firstPane, secondPane] = splits
      
      viewsArray = [firstPane, secondPane]
      
      if arguments.length
        editor.getActiveCodeField().setData 'isFile', yes
        parent.addSubView newSplit = new EditorSplitView 
          views: viewsArray
          sizes: ['50%', '50%']
          type: event.splitType
        editor.destroy()
      else 
        newSplit = new EditorSplitView 
          views: viewsArray
          sizes: ['50%', '50%']
          type: event.secondSplitType

    for split in event.splits
      individualSplits.push @createPlaceholder editor, options if split is 1
      individualSplits.push createSplit() if split is 2
      
    createSplit individualSplits
    @propagateEvent { KDEventType : 'StartTabSplittedViewStarted', globalEvent : yes }

  createPlaceholder:(editor, options)->
    placeholder =  new SplitPlaceholder file: editor.file, fileItem: editor.fileItem, delegate: editor.delegate, splittable: @, doNotPullContent: yes

    placeholder.listenTo
      KDEventTypes: 'SplittedViewStartFromScratch'
      listenedToInstance: placeholder
      callback: =>
        @propagateEvent { KDEventType : 'StartTabSplittedViewEnded', globalEvent : yes }
        # createEditor {path : "~~~/no-such-path/untitled.txt", new: yes, name: 'Untitled.txt', contents: ""}, no
        @createEditor docManager.getUntitledFile(), no, placeholder, editor, options

    placeholder.listenTo
      KDEventTypes: 'SplittedViewSplitFile'
      listenedToInstance: placeholder
      callback: =>
        @propagateEvent { KDEventType : 'StartTabSplittedViewEnded', globalEvent : yes }
        newCodeField = @createEditor editor.file, no, placeholder, editor, options
        newContents  = editor.getValue()
        newCodeField.openFile loadContent: yes, file: editor.file
        newCodeField.listenTo
          KDEventTypes: 'ready'
          listenedToInstance: newCodeField
          callback: ->
            newCodeField.setValueWithoutEventPropagations newContents
        # newCodeField.openFile loadContent: yes, file: {
        #   contents: editor.getValue()
        #   path: editor.file.path
        # }

    placeholder.listenTo
      KDEventTypes: 'SplittedViewDroppedFile'
      listenedToInstance: placeholder
      callback: (pubInst, event) =>
        @propagateEvent { KDEventType : 'StartTabSplittedViewEnded', globalEvent : yes }
        @createEditor event.file, yes, placeholder, editor, options

    placeholder.listenTo
      KDEventTypes: 'SplittedViewClose'
      listenedToInstance: placeholder
      callback: (placeholder, event) =>
        @removeEditor placeholder

    placeholder

  createEditor:(file, pullContent, thisPlaceholder, editor, options) ->
    panel         = thisPlaceholder.parent
    panelHolder   = panel.parent
    
    newCodeField = new Editor_CodeField 
      file: file
      fileItem: null
      delegate: editor.delegate
      splittable: @
      pullContentAfterOpening: pullContent
    @setEventListeners newCodeField, options

    docManager.addOpenDocument file
    # newSplit.rawItems[1] = newCodeField

    thisPlaceholder.destroy()
    index = panelHolder.getOptions().views.indexOf thisPlaceholder
    if index > -1 #updating panel holder views
      panelHolder.getOptions().views.splice index, 1
      panelHolder.getOptions().views.push newCodeField
    
    panel.addSubView newCodeField
    panel.setDelegate newCodeField
    newCodeField.openFile {file}
    @registerEditor newCodeField

    newCodeField

  registerEditor: (editor) ->
    @_editors.push editor

  registerSplit: (split) ->
    @_splits.push split

  unregisterEditor: (editor) ->
    index = @_editors.indexOf editor
    if index > -1
      @_editors.splice index, 1

  getEditors: ->
    @_editors

  removeEditor: (editor) ->  
    @unregisterEditor editor
    panel                 = editor.parent
    panelHolder           = panel.parent
    panelHolderContainer  = panelHolder.parent
    
    indexPanelToRemove = panelHolder.panels.indexOf panel
    if indexPanelToRemove > -1
      panelHolder.removePanel indexPanelToRemove
      
    leftThing   = panelHolder.panels[0].subViews[0]
    panelHolderContainer.addSubView leftThing
    
    panelHolder.destroy()
    
    yes


  createFirstEditor: (options)->
    _options = $.extend {}, {delegate: @getDelegate(), splittable: @}, options
    editor = new Editor_CodeField _options
    @registerEditor editor
    @addSubView editor
    @setEventListeners editor, _options
    editor

  addEditor: (options) ->
    @createFirstEditor options

  parentDidResize:(parent, event)->
    if @getSubViews()
      (subView.parentDidResize(parent,event) for subView in @getSubViews())
    # @$(".ace_scroller").css height: @getHeight() - 20 #20 bottom bar height
