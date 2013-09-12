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

    @on "uploadFile", (file, percent)=>
      finder = KD.getSingleton "finderController"
      filePath  = "[#{file.vmName}]#{file.path}"
      finder.treeController.nodes[filePath]?.updateProgressView percent

    @on "uploadStart", (file)=>
      finder = KD.getSingleton "finderController"
      filePath   = "[#{file.vmName}]#{file.path}"
      parentPath = "[#{file.vmName}]#{file.parentPath}"

      file._isBeingUploaded = yes
      nodeView = finder.treeController.nodes[filePath]
      if nodeView
        nodeView.updateProgressView 1
        nodeView.on "abortProgress", => file.abort yes
      else
        finder.treeController.on "NodeWasAdded", (nodeView)->
          if nodeView.getData().path is filePath and file._isBeingUploaded
            nodeView.updateProgressView 1
            nodeView.on "abortProgress", => file.abort yes

        file.save "", -> finder.revealPath parentPath

    @on "uploadEnd", (file)->
      file._isBeingUploaded = no

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
          return new KDNotificationView
            title: "Folder uploads not available for now."

    if files.length >= 20
      return new KDNotificationView
        title   : "Too many files to transfer!"
        content : "Please archive your files and upload again."
        duration: 3000

    if files.length
      lastFile = files.last
      for file, index in files
        sizeInMb = file.size/1024/1024
        if sizeInMb > 50 && @getOptions().uploadToVM
          new KDNotificationView
            type    : "tray"
            title   : "File is too big to upload!"
            content : "#{file.name} is too big to upload, please upload files smaller than 5MB."
            duration: 3000
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
    if uploadToVM
      finder = KD.getSingleton "finderController"
      finder?.revealPath @path

    @addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "cancel"
      cssClass  : "cancel"
      attributes: href: "#"
      click     : => @emit "cancel"

  saveFile: (uploadFile, data)->
    @emit "uploadStart", uploadFile
    uploadFile.saveBinary data, (err, res, progress)=>
      return if err
      if res.finished
        @emit "uploadEnd", uploadFile
      else if res.abort
        @emit "uploadAbort", uploadFile
      else
        @emit "uploadFile", uploadFile, progress.percent

  upload: (file, data)->
    modalStack  = KDModalView.createStack lastToFirst: yes
    uploadDir   = FSHelper.createFileFromPath @path, 'folder'
    uploadFile  = FSHelper.createFileFromPath "#{@path}/#{file}"

    upload      = =>
      uploadFile.exists (err, exists)=>
        unless exists
        then @saveFile uploadFile, data
        else
          modalStack.addModal modal = new KDModalView
            overlay : no
            title   : "Overwrite File?"
            content : """
            <div class="modalformline">
            You already have the file <code>#{uploadFile.path}</code>. Do you want
            to overwrite it?
            </div>
            """
            buttons :
              Overwrite:
                cssClass: "modal-clean-green"
                callback: =>
                  @saveFile uploadFile, data
                  modal.destroy()
              cancel:
                cssClass: "modal-cancel"
                callback: ->
                  modal.destroy()
              "cancel all":
                cssClass: "modal-cancel"
                callback: ->
                  modalStack.destroy()

    uploadDir.exists (err, exists)=>
      unless exists
      then uploadDir.save -> upload()
      else upload()

    return uploadFile
