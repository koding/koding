###
## Main Application controller class
###
class AppController extends KDViewController
  ###
  ##Main Application controller class
  ###
  constructor:()->
    ###
    The application controller will be instantiated when the module is loaded, before the methods are exposed to the ApplicationManager.
    ###
    super
    
  initApplication:(options,callback)=>
    ###
    Application initialization code
    
    This is called by the ApplicationManager when it wants the application to initialize.
    When the application is finished initializing, fire the callback and propagate the event 'ApplicationInitialized'.
    This is where we can apply a style sheet for this application:
    
        @_applyStyleSheet ()=>  
          callback?()  
          @propagateEvent  
            KDEventType : 'ApplicationInitialized', globalEvent : yes
    ###
    @openDocuments  = []
    @_applyStyleSheet ()=>
      callback()
      @propagateEvent
        KDEventType : 'ApplicationInitialized', globalEvent : yes
  
  bringToFront:()=>
    ###
    This is called by the ApplicationManager when it wants the applicatin to show it's window
    
    This is not called in the case of an application having a plugin, and that plugin being called, or in the case of view-less applications
    
    After doing whatever preparation is necessary the application should propagate the 'ApplicationWantsToBeShown' event, passing an object with options and data properties as follows:
    
        options :
          name : 'Application Name'
          type : none | 'application' | 'background'
          <tabHandleView> : new TabHandleView
          hiddenHandle : yes/no (whether the application has a visible tab handle)
        data    :
          application view to be shown by the ApplicationManager
    
    Example:
    
        @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
          options :
            name : 'Application Name'
            type : 'application'
            tabHandleView : new TabHandleView()
            hiddenHandle:no
          data : @getView()
    ###
    unless frontDocument
      if @_doesOpenDocumentsExist()
        frontDocument = @_getFrontDocument()
      else
        frontDocument = @_createNewDocument()
        @autoCreatedDocument = frontDocument

    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle   : no
        type          : 'application'
        name          : frontDocument.getName()
        tabHandleView : frontDocument.tab or= new AceTabHandleView
        controller    : @
      data : frontDocument
    
  initAndBringToFront:(options,callback)=>
    ###
    Called when the application wants to bringToFront an application that hasn't yet been initialized. Default contents:
    
        @initApplication options, =>
          @bringToFront()
          callback()
    ###
    @initApplication options, =>
      @bringToFront()
      callback()
  
  setEnvironment:(@environment)->
  getEnvironment:->@environment

  _doesOpenDocumentsExist:()->
    if @openDocuments.length > 0 then yes else no

  _getOpenDocuments:()->
    @openDocuments

  _getFrontDocument:()->  
    [backDocuments...,frontDocument] = @_getOpenDocuments()
    frontDocument
  
  _addOpenDocument:(document)->
    @openDocuments.push document
    
  _removeOpenDocument:(document)->
    @openDocuments.splice (@openDocuments.indexOf document), 1

  # _createNewDocument:()->
  #   document = new PreviewerView()
  #   document.registerListener KDEventTypes:"viewIsReady", callback:@_loadDocumentView, listener:@
  #   document.registerListener KDEventTypes:'ViewClosed', listener:@, callback:@_closeDocument
  #   @_addOpenDocument document
  #   document
  # 
  _closeDocument:(document)->
    document.parent.removeSubView document
    @_removeOpenDocument document
    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : document
    document.destroy()
  
  newFile:()->
    document = @_createNewDocument()
    @bringToFront document
    
  _getDocumentWhichOwnsThisFile: (file) ->
    for document in @_getOpenDocuments()
      if document.file is file
        return document
    null

  #required
  openFile: (file, options = {})=>
    document = @_getDocumentWhichOwnsThisFile file
    if document
      @bringToFront document
      document.highlight()
    else    
      frontDocument = @_getFrontDocument()
      if not frontDocument?.file.isModified() and @autoCreatedDocument is frontDocument
        documentToClose = frontDocument
      document = @_createNewDocument file
      @bringToFront document
      if documentToClose?
        @closeDocument documentToClose
  
  _applyStyleSheet:(callback)->
    ###
    This is an example of applying your own styles to the application:
    
        requirejs ["text!KDApplications/Shell.kdapplication/app.css?#{KD.version}"], (css)->
          $("<style type='text/css'>#{css}</style>").appendTo("head");
          callback?()
    ###
    requirejs ["text!KDApplications/Shell.kdapplication/app.css?#{KD.version}"], (css)->
      $("<style type='text/css'>#{css}</style>").appendTo("head");
      callback?()
  
  
  

  _loadDocumentView:(documentView)->
    if (file = documentView.file)?
      document.openPath file.path
  # loadView:(mainView)->
  #   ###
  #   Will be called when the application view is appended.
  #   ###


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