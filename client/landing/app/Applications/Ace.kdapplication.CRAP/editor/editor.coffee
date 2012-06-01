class Editor extends KDView
  saveContents:(callback)->
    @getActiveCodeField().saveContents callback

  saveContentAs: (callback) ->
    @getActiveCodeField().saveContentAs callback

  viewAppended:()->  
    @listenWindowResize()
    @file = @getData().file
    @tabPane = @getDelegate()
    @appendContent()
    @listenTo
      KDEventTypes        : [ eventType : "EditorSearchFormDidHide" ]
      listenedToInstance  : @
      callback            : @searchFormDidHide
      
    @listenTo
      KDEventTypes        : [eventType: "EditorSearchFormShow"]
      listenedToInstance  : @
      callback            : =>
        @handleEvent { type : "ToggleSearchReplaceForm" }
    
    # bind this to cmd/ctrl + f
    @listenTo
      KDEventTypes        : [ eventType : "EditorSearchFormDidShow" ]
      listenedToInstance  : @
      callback            : @searchFormDidShow
    @listenTo
      KDEventTypes        : [ eventType : "EditorFind" ]
      listenedToInstance  : @
      callback            : @find
    @listenTo
      KDEventTypes        : [ eventType : "EditorReplace" ]
      listenedToInstance  : @
      callback            : @replace
    @listenTo
      KDEventTypes        : [eventType : 'EditorSearchFormOptionsShow']
      listenedToInstance  : @
      callback            : @showSearchFormOptions
    @listenTo
      KDEventTypes        : [eventType : 'EditorTryToCompile']
      listenedToInstance  : @
      callback            : @tryToCompile
    
    @listenTo
      KDEventTypes        : [eventType : 'EditorTryToRun']
      listenedToInstance  : @
      callback            : @tryToRun
    
    @listenTo
      KDEventTypes        : [eventType : 'EditorTryToAutocomplete']
      listenedToInstance  : @
      callback            : @tryToAutocomplete


  _windowDidResize:()=>
    @doResize()
  
  doResize: ->
    searchHeight = if @searchForm.collapsed then 0 else @searchForm.getHeight()
    @splittable.setHeight (newHeight = @getHeight() - searchHeight)
    @getActiveCodeField().handleEvent type : "RerenderAceSize"

  appendContent:()->
    @addSubView @searchForm = new Editor_SearchForm delegate : @
    @addSubView @splittable = new SplittableCodeField delegate: @
    # @addSubView @bottomBar  = new Editor_BottomBar delegate : @

    # console.log 'append content', @getPageEditor()
    
    @splittable.addEditor file: @file, fileItem: @getDelegate().fileItem
    @listenTo
      KDEventTypes: 'EditorCodeViewInFocus'
      listenedToInstance: @splittable
      callback: (pubInst, event) =>
        if @_activeCodeField isnt event.codeField
          @handleEvent type: 'EditorCodeViewInFocus', codeField:event.codeField #bubbling up event
        @_activeCodeField = event.codeField
        # @splittable.$(".ace_scroller").css height: @getHeight() - 20 #20 bottom bar height
        
        

  getActiveCodeField: ->
    @_activeCodeField

  getFileExtension: (file) ->
    fileName = ''
    if file.path
      fileName = file.path
    else
      fileName = file.title

    extension = __utils.getFileExtension fileName

  tryToAutocomplete: (pubInst, event) ->
    @getActiveCodeField().tryToAutocomplete(event)

  getActiveSyntaxName: ->
    @getActiveCodeField().getActiveSyntaxName()

  tryToRun: ->
    @getActiveCodeField().tryToRun()

  tryToCompile: ->
    # console.log 'accc'
    @getActiveCodeField().tryToCompile()

  _getOption: (name) ->
    extensionName         = @getFileExtension @file
    option                = @getPageEditor().getAppPreferences().bucket[extensionName + '.' + name]

  getPageEditor: ->
    @getDelegate()

  getLastSearchOptions: ->
    @getActiveCodeField().getLastSearchOptions()

  setSearchOptions: (options) ->
    @getActiveCodeField().setSearchOptions options

  keyDown:(e)->#log e,"<--"

  find: (pubInst, event) ->
    @getActiveCodeField().find pubInst, event

  replace:(pubInst,event)->
    @getActiveCodeField().replace pubInst, event

  showSearchFormOptions: ->
    unless @constructor._searchOptionsWindow
      @constructor._searchOptionsWindow = new Editor_SearchForm_Options 
        delegate  : @
        fx        : yes
        height    : "auto"
        
      @constructor._searchOptionsWindow.on 'destroy', =>
        delete @constructor._searchOptionsWindow

  searchFormDidHide:()->
    @doResize()

  searchFormDidShow:()->
    @doResize()
    @searchForm.inputSearch.inputSetFocus()
