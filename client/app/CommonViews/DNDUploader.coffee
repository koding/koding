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

    @on "uploadFile", (file)=>
      new KDNotificationView
        type    : "tray"
        title   : file.name
        content : """
        #{file.name} successfully uploaded to #{file.parentPath}!
        """
        duration: 5000

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
    {files}  = event.originalEvent.dataTransfer
    if files.length
      lastFile = files.last
      for file, index in files
        sizeInMb = file.size/1024/1024
        if sizeInMb > 5 && @getOptions().uploadToVM
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

  showCancel:->
    @addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "cancel"
      cssClass  : "cancel"
      attributes: href: "#"
      click     : => @emit "cancel"

  upload: (file, data)->
    modalStack  = KDModalView.createStack lastToFirst: yes
    uploadDir   = FSHelper.createFileFromPath @path, 'folder'
    uploadFile  = FSHelper.createFileFromPath "#{@path}/#{file}"

    upload      = =>

      uploadFile.exists (err, exists)=>
        unless exists
        then uploadFile.save data, => @emit "uploadFile", uploadFile
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
                  uploadFile.save data, => @emit "uploadFile", uploadFile
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
