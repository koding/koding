class AppController extends KDViewController
  initApplication:(options, callback)=>
    @documentControllersByFileId = {}
    @openDocuments  = []
    {environment} = options
    controller = @
    @setEnvironment environment
    
    requirejs ["js/KDApplications/CodeMirror.kdapplication/lib/codemirror.js", "text!KDApplications/CodeMirror.kdapplication/lib/codemirror.css", "text!KDApplications/CodeMirror.kdapplication/app.css"], (js, CodeMirrorCss, css)->
      $("<style type='text/css'>#{CodeMirrorCss}</style>").appendTo("head");
      $("<style type='text/css'>#{css}</style>").appendTo("head");
      callback()
      controller.propagateEvent
        KDEventType : 'ApplicationInitialized', globalEvent : yes
  
  bringToFront:(frontDocument)=>
    unless frontDocument
      if @_doesOpenDocumentsExist()
        frontDocument = @_getFrontDocument()
        @sendPropagationEvent frontDocument
      else
        @_createNewDocument (frontDocument)=>
          @autoCreatedDocument = frontDocument
          @sendPropagationEvent frontDocument 
      @_addOpenDocument document
      
    else      
      autoCreated = @autoCreatedDocument is frontDocument
      @_getFrontDocument()?.propagateEvent KDEventType:"DocumentMovedBack", {autoCreated}
      @sendPropagationEvent frontDocument
      

  initAndBringToFront:(options, callback)=>
    @initApplication options, =>
      @bringToFront()
      callback()
  
  sendPropagationEvent:(frontDocument)->
    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle    : no
        type            : 'application'
        name            : frontDocument.getName()
        controller      : @
        applicationType : 'CodeMirror.kdapplication'
      data : frontDocument
    
  
  setStorage:(savedStorage)->
    storage = savedStorage
    savedStorage.bucket = $.extend yes, defaultStorage, savedStorage.bucket
    AppStorageQueue.appStorageLoaded()
  
  setEnvironment:(env)->
    environment = env
  getEnvironment:->environment

  _doesOpenDocumentsExist:()->
    if @openDocuments.length > 0 then yes else no

  _getOpenDocuments:()->
    @openDocuments

  _getFrontDocument:()->  
    [backDocuments...,frontDocument] = @_getOpenDocuments()
    frontDocument
  
  _addOpenDocument:(document)->
    docManager.addOpenDocument document.file
    appManager.addOpenTab document, "CodeMirror.kdapplication"
    @openDocuments.push document
    
  _removeOpenDocument:(document)->
    docManager.removeOpenDocument document.file
    appManager.removeOpenTab document
    @openDocuments.splice (@openDocuments.indexOf document), 1

  _createNewDocument:(file, callback)->
    [callback, file] = [file, callback] unless callback?
    
    appController = @
    file or= docManager.getUntitledFile()
    AppStorageQueue.waitForAppStorage ->
      docController = new DocumentController delegate : appController, file
      appController.documentControllersByFileId[file.getId()] = docController
      document = docController.getView()
      document.file = file
      document.untitledNumber = file.untitledNumber if file.untitledNumber?
      document.registerListener KDEventTypes:'ViewClosed', listener:appController, callback:appController._closeDocument
      appController._addOpenDocument document
      callback document
  
  _closeDocument:(document)->
    document.parent.removeSubView document
    @_removeOpenDocument document
    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : document
    document.destroy()
  
  newFile:()->
    @_createNewDocument (document)=>
      @bringToFront document
    
  _getDocumentWhichOwnsThisFile: (file) ->
    @documentControllersByFileId[file.getId()]?.getView() or null

  openFile: (file, options = {})=>
    document = @_getDocumentWhichOwnsThisFile file
    if document
      document.file = file
      @bringToFront document
    else
      @_createNewDocument file, (document)=>
        @bringToFront document


class AppStorageQueue
  callbackQueue = []
  appStorageIsLoaded = no
  
  @waitForAppStorage = (callback)->
    if appStorageIsLoaded then callback() else callbackQueue.push callback
  
  @appStorageLoaded = ->
    appStorageIsLoaded = yes
    callback() for callback in callbackQueue


class TabHandleView extends KDView
  ###
  ## TabHandleView (optional) ##
  You can optionally pass an instance of this class with the options of the "ApplicationWantsToBeShown" event
  ###
  setDomElement:()->
    ###
    Example of customizing the tab view
    ###
    @domElement = $ "<b>AppName</b>
      <span class='kdcustomhtml appClass icon'></span>
      <span class='close-tab'></span>"

###
# Application Exports #
###
define ()->
  application = new AppController()
  {initApplication, initAndBringToFront, bringToFront, openFile, newFile} = application
  {initApplication, initAndBringToFront, bringToFront, openFile, newFile}
  #the reason I'm returning the whole instance right now is because propagateEvent includes the whole thing anyway. switch to emit/on and we can change this...
  return application