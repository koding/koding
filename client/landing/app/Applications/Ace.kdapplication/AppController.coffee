class Ace12345 extends KDController
  
  constructor:->
    
    super
    @aceViews  = {}
    @setFSListeners()

  bringToFront:(view)->
    
    if view
      file = view.getData()
    else
      file = @getSingleton('docManager').createEmptyDocument()
      view = new AceView {}, file
    
    options =
      name         : file.name || 'untitled'
      hiddenHandle : no
      type         : 'application'

    @aceViews[file.path] = view
    
    @setViewListeners view

    data = view
    @propagateEvent
      KDEventType  : 'ApplicationWantsToBeShown'
      globalEvent  : yes
    , {options, data}

  initAndBringToFront:(options,callback)->
    @bringToFront()
    callback()

  isFileOpen:(file)-> @aceViews[file.path]?
  
  openFile:(file)->
    unless @isFileOpen file
      @bringToFront new AceView {}, file

  removeOpenDocument:(doc)->
    appManager.removeOpenTab doc
    @clearFileRecords doc

  setViewListeners:(view)->
    @listenTo 
      KDEventTypes       : 'ViewClosed',
      listenedToInstance : view
      callback           : (doc)=>
        # doc.parent.removeSubView doc
        @removeOpenDocument doc

        @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : doc
        doc.destroy()
    
    @listenTo 
      KDEventTypes       : "KDObjectWillBeDestroyed"
      listenedToInstance : view
      callback           : ()=>
        @clearFileRecords view

    file = view.getData()

    file.on "fs.remotefile.created", (oldPath)=>
      delete @aceViews[oldPath]
      @aceViews[file.path]
      view.parent.setTitle file.name

  setFSListeners:->
    
    FSItem.on "fs.saveAs.finished", (newFile, oldFile)=>

      if @aceViews[oldFile.path]
        view = @aceViews[oldFile.path]
        @clearFileRecords view
        @aceViews[newFile.path] = view
        view.setData newFile
        view.ace.setData newFile

  clearFileRecords:(view)->
    file = view.getData()
    delete @aceViews[file.path]