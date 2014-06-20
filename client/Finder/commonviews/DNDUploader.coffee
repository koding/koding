class DNDUploader extends KDView

  constructor: (options={}, data)->

    options.cssClass      = KD.utils.curry "file-droparea", options.cssClass
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

    @on "uploadFile", (fsFile, percent) =>
      @emit 'uploadProgress', { file: fsFile, percent }

    @on "uploadStart", (fsFile) =>
      filePath   = "[#{fsFile.vmName}]#{fsFile.path}"
      parentPath = "[#{fsFile.vmName}]#{fsFile.parentPath}"

      fsFile.save "", => @emit 'uploadComplete', { filePath, parentPath }

  viewAppended: ->
    super

  reset: ->
    {uploadToVM, defaultPath, title} = @getOptions()
    @setPath()
    @updatePartial """
      <div class="file-drop">
        #{title or "Drop files here!"}
        <small>#{if uploadToVM then defaultPath else ''}</small>
      </div>
    """
    @_uploaded = {}

  drop: (event)->
    super
    {files, items}  = event.originalEvent.dataTransfer

    if files.length >= 20
      KD.notify_ """
      Too many files to transfer!<br>
      Archive your files and try again.
      """, "error", """
      Max 20 files allowed to upload at once.
      You can archive your files and try again.
      """

    if items?.item?(0)?.webkitGetAsEntry
      for item in items
        entry = item.webkitGetAsEntry()
        if entry.isDirectory
          @walkDirectory entry.filesystem.root, (file)=>
            # upload walked file
            @uploadFiles [file], event
          , =>
            # fallback for file upload, upload the other files stack
            @uploadFiles files, event
        else if entry.isFile
          entry.file (file)=>
            # upload file entry
            @uploadFiles [file], event
    else
      # fallback to upload files for folder upload browsers
      @uploadFiles files, event

  uploadFiles: (files, event)->
    @_uploaded or= {}
    if files?.length

      lastFile = files.last

      for file, index in files
        sizeInMb = file.size/1024/1024
        if sizeInMb > 100 && @getOptions().uploadToVM
          KD.notify_ "Too big file to upload.", "error", "Max 100MB allowed per file."
          continue
        reader = new FileReader
        reader.onloadend = do (file=files[index])=> (readEvent)=>

          fileName = file.fileName or file.name

          if file.relativePath
            return if @_uploaded[file.relativePath + fileName]
            @_uploaded[file.relativePath + fileName] = yes

          if @getOptions().uploadToVM
            fsFile = @upload fileName, readEvent.target.result, file.relativePath

          @emit "dropFile",
            origin  : "external"
            filename: fileName
            path    : file.relativePath or no
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
          fsFile = FSHelper.createFileInstance path: item
          @emit "dropFile",
            origin  : "internal"
            filename: basename
            instance: fsFile
            content : null
            isLast  : item is lastItem
          , event, no

          @reset() if item is lastItem

  walkDirectory: (dirEntry, callback, error)->

    dirReader = dirEntry.createReader()
    relative  = FSHelper.convertToRelative dirEntry.fullPath

    dirReader.readEntries (entries)=>
      for entry in entries
        if entry.isFile
          entry.file (file)->
            file.relativePath = relative + file.name
            callback file
        else @walkDirectory entry, callback, error
    , error

  setPath: (@path = @getOptions().defaultPath) ->
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

  showCancel: ->
    @addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "cancel"
      cssClass  : "cancel"
      attributes: href: "#"
      click     : => @emit "cancel"

  saveFile: (fsFile, data) ->
    @emit "uploadStart", fsFile
    fsFile.saveBinary data, (err, res, progress)=>
      progress or= res
      return if err
      if res.finished
        @emit "uploadEnd", fsFile
      else if res.abort
        @emit "uploadAbort", fsFile
      else
        @emit "uploadFile", fsFile, progress.percent

  upload: (fileName, contents, relativePath)->

    folder = if relativePath and relativePath isnt fileName
    then "#{@path}/#{relativePath.replace /\/[^\/]*$/, ''}"
    else @path

    modalStack   = KDModalView.createStack lastToFirst: yes
    fsFolderItem = FSHelper.createFileInstance path: folder, type: 'folder'
    fsFileItem   = FSHelper.createFileInstance path: "#{folder}/#{fileName}"

    return if FSHelper.isUnwanted fsFolderItem.path
    return if FSHelper.isUnwanted fsFileItem.path, yes

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
      then FSHelper.createRecursiveFolder fsFolderItem, -> upload()
      else upload()

    return fsFileItem
