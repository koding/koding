class Viewer12345 extends KDViewController
  initApplication:(options,callback)=>
    @openDocuments = []
    # console.log 'init application called'
    # @applyStyleSheet ()=>
    @propagateEvent
      KDEventType : 'ApplicationInitialized', globalEvent : yes
    callback()

  initAndBringToFront:(options,callback)=>
    # console.log 'initAndBringToFront'
    @initApplication options, =>
      @bringToFront null, callback

  bringToFront:(frontDocument, path, callback)=>
    unless frontDocument
      if @doesOpenDocumentsExist()
        frontDocument = @getFrontDocument()
      else
        frontDocument = @createNewDocument()
    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle    :no
        type            :'application'
        name            : path
        applicationType : 'Viewer.kdApplication'
      data : frontDocument
    
    callback()

  openFile: (path, options = {})=>
    document = @createNewDocument() unless (document = @getFrontDocument())?.isDocumentClean()
    @bringToFront document, path, ->
      document.openPath path

  doesOpenDocumentsExist:()->
    if @openDocuments.length > 0 then yes else no

  getOpenDocuments:()->
    @openDocuments

  getFrontDocument:()->  
    [backDocuments...,frontDocument] = @getOpenDocuments()
    frontDocument
  
  addOpenDocument:(document)->
    appManager.addOpenTab document, 'Viewer.kdApplication'
    @openDocuments.push document
    
  removeOpenDocument:(document)->
    appManager.removeOpenTab document, @
    @openDocuments.splice (@openDocuments.indexOf document), 1

  createNewDocument:()->
    # document = new PreviewerView cssClass : 'previewer-wrapper'
    # document.addSubView header  = new PreviewerHeader cssClass : 'previewer-header', delegate : document
    # document.addSubView preview = new Previewer delegate : document
    document = new PreviewerView()
    document.registerListener KDEventTypes:"viewAppended", callback:@loadDocumentView, listener:@
    document.registerListener KDEventTypes:'ViewClosed', listener:@, callback:@closeDocument
    @addOpenDocument document
    document
  
  closeDocument:(document)->
    document.parent.removeSubView document
    @removeOpenDocument document
    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : document
    document.destroy()

  loadDocumentView:(documentView)->
    if (file = documentView.file)?
      document.openPath file.path
  
  # applyStyleSheet:(callback)->
  #   requirejs ['text!KDApplications/Viewer.kdapplication/app.css'], (css)->
  #     $("<style type='text/css'>#{css}</style>").appendTo("head");
  #     callback?()

# define ()->
#   application = new AppController()
#   {initApplication, initAndBringToFront, bringToFront, openFile} = application
#   {initApplication, initAndBringToFront, bringToFront, openFile}
#   #the reason I'm returning the whole instance right now is because propagateEvent includes the whole thing anyway. switch to emit/on and we can change this...
#   return application


class PreviewerView extends KDView
  constructor:(options = {},data)->
    options.cssClass = 'previewer-body'
    @clean = yes
    super options,data
    
  openPath:(path)->
    @path = path
    @clean = no
    @iframe.$().attr 'src', path
    @viewerHeader.setPath(path)
  
  refreshIFrame:->
    @iframe.$().attr 'src', @path
    
  isDocumentClean:->
    @clean
  
  viewAppended:->
    @addSubView @viewerHeader = new ViewerTopBar {}, null
    @addSubView @iframe = new KDView
      tagName : 'iframe'


class ViewerTopBar extends KDView
  constructor:(options,data)->
    options.cssClass = 'viewer-header top-bar clearfix'
    super options,data

    @pageLocation = pageLocation = new KDView
      tagName   : 'p'
      cssClass  : 'viewer-title'
      partial   : ''
      
    @refreshButton = refreshButton = new PreviewerButton {}, @getData()
    
  viewAppended:->
    @addSubView @pageLocation = new KDView
      tagName   : 'p'
      cssClass  : 'viewer-title'
      partial   : ''
    @addSubView @refreshButton = new PreviewerButton {}, null

  setPath:(path)->
    @pageLocation.$().text "#{path}"
      
      
class PreviewerButton extends KDView
  constructor:(options, data)->
    options = $.extend
      tagName   : 'button'
      cssClass  : 'clean-gray'
      partial   : '<span class="icon refresh-btn"></span>'
    , options
    super options, data
    
  click:=>
    @parent.parent.refreshIFrame()

    

    
    
    
    
    
    
    
