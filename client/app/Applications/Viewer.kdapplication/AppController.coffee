class ViewerAppController extends KDViewController
  initApp:(options,callback)->
    @openDocuments = []
    # log 'init application called'
    # @applyStyleSheet ()=>
    @propagateEvent
      KDEventType : 'ApplicationInitialized', globalEvent : yes
    callback()

  bringToFront:(frontDocument, path, callback)->
    unless frontDocument
      if @doesOpenDocumentsExist()
        frontDocument = @getFrontDocument()
      else
        frontDocument = @createNewDocument()
    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle    : no
        type            : 'application'
        name            : path
        applicationType : 'Viewer.kdApplication'
      data : frontDocument

    callback()

  openFile: (path, options = {})->
    doc = @createNewDocument() unless (doc = @getFrontDocument())?.isDocumentClean()
    @bringToFront doc, path, ->
      doc.openPath path

  doesOpenDocumentsExist:()->
    if @openDocuments.length > 0 then yes else no

  getOpenDocuments:()->
    @openDocuments

  getFrontDocument:()->
    [backDocuments...,frontDocument] = @getOpenDocuments()
    frontDocument

  addOpenDocument:(doc)->
    appManager.addOpenTab doc, 'Viewer.kdApplication'
    @openDocuments.push doc

  removeOpenDocument:(doc)->
    appManager.removeOpenTab doc, @
    @openDocuments.splice (@openDocuments.indexOf doc), 1

  createNewDocument:()->
    doc = new PreviewerView()
    doc.on "viewAppended", @loadDocumentView.bind @
    doc.on 'ViewClosed', => @closeDocument doc
    @addOpenDocument doc
    return doc

  closeDocument:(doc)->
    doc.parent.removeSubView doc
    @removeOpenDocument doc
    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : doc
    doc.destroy()

  loadDocumentView:(docView)->
    if (file = docView.file)?
      doc.openPath file.path
