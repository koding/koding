class DNDUploader extends KDView

  constructor: (options={}, data)->

    options.cssClass      = "file-droparea"
    options.bind          = "dragenter dragover dragleave dragend drop"
    options.hoverDetect  ?= yes
    options.uploadToVM   ?= yes
    options.defaultPath or= "/home/#{KD.nick()}/Uploads"

    super options, data

    @reset()

    @setPath options.path  if options.path

    if options.hoverDetect
      @on "dragenter", => @setClass   "hover"
      @on "dragover",  => @setClass   "hover"
      @on "dragleave", => @unsetClass "hover"
      @on "drop",      => @unsetClass "hover"

    @on "uploadFile", (fsFile, percent)=>
      filePath  = "[#{fsFile.vmName}]#{fsFile.path}"
      @finder.treeController.nodes[filePath]?.showProgressView percent

    @on "uploadStart", (fsFile)=>
      filePath   = "[#{fsFile.vmName}]#{fsFile.path}"
      parentPath = "[#{fsFile.vmName}]#{fsFile.parentPath}"

      bindAbort = ->
        nodeView.showProgressView 1
        nodeView.once "abortProgress", => fsFile.abort yes

      fsFile._isBeingUploaded = yes
      nodeView = @finder.treeController.nodes[filePath]
      if nodeView
      then bindAbort()
      else
        @finder.treeController.on "NodeWasAdded", (nodeView)->
          if nodeView.getData().path is filePath and fsFile._isBeingUploaded
            bindAbort()

        fsFile.save "", =>
          @finder.expandFolders FSHelper.getPathHierarchy parentPath

    @on "uploadEnd", (fsFile)->
      fsFile._isBeingUploaded = no

  viewAppended: ->
    super
    @finder = KD.getSingleton "finderController"
    tc      = @finder.treeController
    @notify = tc.notify.bind tc

  reset: ->
    {uploadToVM, defaultPath, title} = @getOptions()
    @setPath()
    @updatePartial """
      <div class="file-drop">
        #{title or "Drop files here!"}
        <small>#{if uploadToVM then defaultPath else ''}</small>
      </div>
    """

  drop: (event)->
    super
    {files, items}  = event.originalEvent.dataTransfer
    # folders are not allowed
    if items.length
      for item in items
        itemEntry = item.webkitGetAsEntry?()
        if itemEntry.isDirectory
          return @notify "Folder uploads not available for now.", "error"

    if files.length >= 20
      @notify """
      Too many files to transfer!<br>
      Archive your files and try again.
      """, "error", """
      Max 20 files allowed to upload at once.
      You can archive your files and try again.
      """

    if files.length
      lastFile = files.last
      for file, index in files
        sizeInMb = file.size/1024/1024
        if sizeInMb > 100 && @getOptions().uploadToVM
          @notify "Too big file to upload.", "error", "Max 100MB allowed per file."
          continue
        reader = new FileReader
        reader.onloadend = do (file=files[index])=> (readEvent)=>
          if @getOptions().uploadToVM
            fsFile = @upload file.name, readEvent.target.result
          @emit "dropFile",
            origin  : "external"
            filename: file.name
            instance: fsFile
            content : readEvent.target.result
            isLast  : file is lastFile
          , event, readEvent

          @reset() if file is lastFile

        reader.readAsBinaryString file
    else
      internalData = event.originalEvent.dataTransfer.getData "Text"
      if internalData
        multipleItems = internalData.split ","
        lastItem = multipleItems.last
        for item in multipleItems
          {basename} = KD.getPathInfo item
          fsFile = FSHelper.createFileFromPath item
          @emit "dropFile",
            origin  : "internal"
            filename: basename
            instance: fsFile
            content : null
            isLast  : item is lastItem
          , event, no

          @reset() if item is lastItem

  setPath: (@path=@options.defaultPath)->
    {uploadToVM, title} = @getOptions()
    @updatePartial """
      <div class="file-drop">
        #{title or "Drop files here!"}
        <small>#{if uploadToVM then (FSHelper.getVMNameFromPath(@path) or '') else ''}</small>
        <small>#{if uploadToVM then FSHelper.plainPath @path else ''}</small>
      </div>
    """
    @showCancel()
    if uploadToVM and @finder
      @finder.expandFolders FSHelper.getPathHierarchy @path

  showCancel:->
    @addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "cancel"
      cssClass  : "cancel"
      attributes: href: "#"
      click     : => @emit "cancel"

  saveFile: (fsFile, data)->
    @emit "uploadStart", fsFile
    fsFile.saveBinary data, (err, res, progress)=>
      return if err
      if res.finished
        @emit "uploadEnd", fsFile
      else if res.abort
        @emit "uploadAbort", fsFile
      else
        @emit "uploadFile", fsFile, progress.percent

  upload: (fileName, contents)->
    modalStack   = KDModalView.createStack lastToFirst: yes
    fsFolderItem = FSHelper.createFileFromPath @path, 'folder'
    fsFileItem   = FSHelper.createFileFromPath "#{@path}/#{fileName}"

    upload = =>
      fsFileItem.exists (err, exists)=>
        if not exists or fsFileItem.getLocalFileInfo().lastUploadedChunk?
        then @saveFile fsFileItem, contents
        else
          modalStack.addModal modal = new KDModalView
            overlay : no
            title   : "Overwrite File?"
            content : """
            <div class="modalformline">
            You already have the file <code>#{fsFileItem.path}</code>. Do you want
            to overwrite it?
            </div>
            """
            buttons :
              Overwrite:
                cssClass: "modal-clean-green"
                callback: =>
                  @saveFile fsFileItem, contents
                  modal.destroy()
              cancel:
                cssClass: "modal-cancel"
                callback: ->
                  modal.destroy()
              "cancel all":
                cssClass: "modal-cancel"
                callback: ->
                  modalStack.destroy()

    fsFolderItem.exists (err, exists)=>
      unless exists
      then fsFolderItem.save -> upload()
      else upload()

    return fsFileItem
