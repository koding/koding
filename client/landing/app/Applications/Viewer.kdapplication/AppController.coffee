class Viewer12345 extends KDViewController
  initApplication:(options,callback)=>
    @openDocuments = []
    # log 'init application called'
    # @applyStyleSheet ()=>
    @propagateEvent
      KDEventType : 'ApplicationInitialized', globalEvent : yes
    callback()

  initAndBringToFront:(options,callback)=>
    # log 'initAndBringToFront'
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
        hiddenHandle    : no
        type            : 'application'
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
    document = new PreviewerView()
    document.on "viewAppended", @loadDocumentView.bind @
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

class PreviewerView extends KDView

  constructor:(options = {},data)->
    options.cssClass = 'previewer-body'
    super options,data

  openPath:(path)->

    # do not open main koding domains in the iframe
    if /(^(http(s)?:\/\/)?beta\.|^(http(s)?:\/\/)?)koding\.com/.test path
      @viewerHeader.pageLocation.setClass "validation-error"
      return

    realPath = unless /^http(s)?:\/\//.test path then "http://#{path}" else path
    cacheBusterPath = "#{realPath}?#{Date.now()}"

    @path = realPath
    @iframe.$().attr 'src', "#{cacheBusterPath}"
    @viewerHeader.setPath realPath

  refreshIFrame:->
    @iframe.$().attr 'src', "#{@path}"

  isDocumentClean:->
    @clean

  viewAppended:->
    @addSubView @viewerHeader = new ViewerTopBar {}, @path
    @addSubView @iframe = new KDCustomHTMLView
      tagName : 'iframe'


class ViewerTopBar extends JView
  constructor:(options,data)->
    options.cssClass = 'viewer-header top-bar clearfix'
    super options,data

    @addressBarIcon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "address-bar-icon"

    @pageLocation = new KDHitEnterInputView
      type      : "text"
      callback  : =>
        @parent.openPath @pageLocation.getValue()
        @pageLocation.focus()

    @refreshButton = new KDCustomHTMLView
      tagName   : "a"
      attributes:
        href    : "#"
      cssClass  : "refresh-link"
      click     : => @parent.refreshIFrame()

  setPath:(path)->
    @pageLocation.unsetClass "validation-error"
    @pageLocation.setValue "#{path}"

  pistachio:->

    """
    {{> @addressBarIcon}}
    {{> @pageLocation}}
    {{> @refreshButton}}
    """
