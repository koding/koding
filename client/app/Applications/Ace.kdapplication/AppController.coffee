class Ace12345 extends KDController
  
  constructor:->
    
    super
    @aceViews  = {}

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
      
    data = view
    
    @aceViews[file.path] = view
    
    @setViewListeners view
    
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

  clearFileRecords:(view)->
    file = view.getData()
    delete @aceViews[file.path]