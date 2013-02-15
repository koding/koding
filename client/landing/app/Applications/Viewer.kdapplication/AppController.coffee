class ViewerAppController extends KDViewController

  KD.registerAppClass @, name : "Viewer"

  initApp:(options,callback)=>
    @openDocuments = []
    # log 'init application called'
    # @applyStyleSheet ()=>
    @propagateEvent
      KDEventType : 'ApplicationInitialized', globalEvent : yes
    callback()

  bringToFront:(frontDocument, path, callback)=>
    unless frontDocument
      if @doesOpenDocumentsExist()
        frontDocument = @getFrontDocument()
      else
        frontDocument = @createNewDocument()

    @emit 'ApplicationWantsToBeShown', @, frontDocument,
      hiddenHandle    : no
      type            : 'application'
      name            : path
      applicationType : 'Viewer.kdApplication'

    callback()

  openFile: (path, options = {})=>
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
    KD.getSingleton("appManager").addOpenTab doc, 'Viewer.kdApplication'
    @openDocuments.push doc

  removeOpenDocument:(doc)->
    KD.getSingleton("appManager").removeOpenTab doc, @
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
