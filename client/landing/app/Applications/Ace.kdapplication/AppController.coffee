class Ace12345 extends KDController

  constructor:->

    super
    @aceViews  = {}

  bringToFront:(view)->

    if view
      file = view.getData()
    else
      file = FSHelper.createFileFromPath "localfile:/Untitled.txt"
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

  isFileOpen:(file)-> @aceViews[file.path]?

  openFile:(file)->

    unless @isFileOpen file
      @bringToFront new AceView {}, file
    else
      # check if this is possible with appManager
      @getSingleton("mainView").mainTabView.showPane @aceViews[file.path].parent


  removeOpenDocument:(doc)->

    if doc
      @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : doc
      appManager.removeOpenTab doc
      @clearFileRecords doc
      doc.destroy()

  setViewListeners:(view)->

    @listenTo
      KDEventTypes       : 'ViewClosed',
      listenedToInstance : view
      callback           : (doc)=> @removeOpenDocument doc

    @setFileListeners view.getData()

  setFileListeners:(file)->

    view = @aceViews[file.path]

    file.on "fs.saveAs.finished", (newFile, oldFile)=>

      if @aceViews[oldFile.path]
        view = @aceViews[oldFile.path]
        @clearFileRecords view
        @aceViews[newFile.path] = view
        view.setData newFile
        view.parent.setTitle newFile.name
        view.ace.setData newFile
        @setFileListeners newFile
        view.ace.notify "New file is created!", "success"
        @getSingleton('mainController').emit "NewFileIsCreated", newFile

    file.on "fs.delete.finished", => @removeOpenDocument @aceViews[file.path]


  clearFileRecords:(view)->
    file = view.getData()
    delete @aceViews[file.path]