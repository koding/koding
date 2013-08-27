class DNDUploader extends KDView

  constructor: (options={}, data)->

    options.cssClass      = "file-droparea"
    options.hoverDetect  ?= yes
    options.uploadToVM   ?= yes
    options.defaultPath or= "/home/#{KD.nick()}/Uploads"

    super options, data
    @reset()

    @setPath options.path  if options.path

    if options.hoverDetect
      @on "dragEnter", => @setClass   "hover"
      @on "dragOver",  => @setClass   "hover"
      @on "dragLeave", => @unsetClass "hover"
      @on "drop",      => @unsetClass "hover"

    @on "uploadFile", (file)=>
      new KDNotificationView
        type    : "tray"
        title   : file.name
        content : """
        #{file.name} successfully uploaded to #{file.parentPath}!
        """
        duration: 5000

  viewAppended: ->

    super

    @$().on "dragenter dragover dragleave dragend drop", (event)=>
      switch event.type
        when "dragenter"  then @dragEnter.call this, event
        when "dragover"   then @dragOver.call  this, event
        when "dragleave"  then @dragLeave.call this, event
        when "dragend"    then @dragEnd.call   this, event
        when "drop"       then @drop.call      this, event

      event.preventDefault()
      event.stopPropagation()

  reset: ->
    {uploadToVM, defaultPath, title} = @getOptions()
    @setPath()
    @updatePartial """
      <div class="file-drop">
        #{title or "Drop files here!"}
        <small>#{if uploadToVM then defaultPath else ''}</small>
      </div>
    """

  dragOver  : (event)-> @emit "dragOver"

  dragEnd   : (event)-> @emit "dragEnd"

  dragLeave : (event)-> @emit "dragLeave"

  dragEnter : (event)-> @emit "dragEnter"

  drop: (event)->
    {files}  = event.originalEvent.dataTransfer
    lastFile = files[files.length-1]
    for file, index in files
      sizeInMb = file.size/1000/1000
      if sizeInMb > 5 && @getOptions().uploadToVM
        new KDNotificationView
          type    : "tray"
          title   : "File is too big to upload!"
          content : "#{file.name} is too big to upload, please upload files smaller than 5mb."
          duration: 3000
        continue
      reader = new FileReader
      reader.onloadend = do (file=files[index])=> (event)=>
        if @getOptions().uploadToVM
          @upload file.name, event.target.result

        if file is lastFile
          @reset()
          @emit "drop", file.name, event.target.result

      reader.readAsBinaryString file

  setPath: (@path=@options.defaultPath)->
    {uploadToVM, title} = @getOptions()
    @updatePartial """
      <div class="file-drop">
        #{title or "Drop files here!"}
        <small>#{if uploadToVM then (FSHelper.getVMNameFromPath(@path) or '') else ''}</small>
        <small>#{if uploadToVM then FSHelper.plainPath @path else ''}</small>
      </div>
    """
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