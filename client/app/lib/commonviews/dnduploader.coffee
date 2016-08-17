kd = require 'kd'
KDView = kd.View
KDModalView = kd.ModalView
KDCustomHTMLView = kd.CustomHTMLView
nick = require '../util/nick'
notify_ = require '../util/notify_'
getPathInfo = require '../util/getPathInfo'
FSHelper = require '../util/fs/fshelper'
FSItem = require '../util/fs/fsitem'
showError = require '../util/showError'
ContentModal = require 'app/components/contentModal'

module.exports = class DNDUploader extends KDView

  constructor: (options = {}, data) ->

    options.cssClass      = kd.utils.curry 'file-droparea', options.cssClass
    options.bind          = 'dragenter dragover dragleave dragend drop'
    options.hoverDetect  ?= yes
    options.uploadToVM   ?= yes

    super options, data

    if options.hoverDetect
      @on 'dragenter', => @setClass   'hover'
      @on 'dragover',  => @setClass   'hover'
      @on 'dragleave', => @unsetClass 'hover'
      @on 'drop',      => @unsetClass 'hover'

    kd.singletons.mainController.ready @bound 'reset'


  reset: ->

    { uploadToVM, defaultPath, title } = @getOptions()

    defaultPath or= "/home/#{nick()}/Uploads"

    @setPath()
    @updatePartial """
      <div class="file-drop">
        #{title or "Drop files here!"}
        <small>#{if uploadToVM then defaultPath else ''}</small>
      </div>
    """
    @_uploaded = {}


  showGenericError: (message) ->

    message or= "
      <p>
        Sorry, you can't upload more than 20 files, and uploading
        folders is only supported for Chrome 21 and above.
      </p>
      <p>
        You can also <a href='http://www.wikihow.com/Make-a-Zip-File' target='_blank'>zip</a>
        your files for faster uploads. Please correct the error and try again.
      </p>
    "

    modal = new ContentModal
      title        : 'Upload File Error'
      width        : 500
      cssClass     : 'content-modal'
      content      : "<div class='modalformline'>#{message}</div>"
      overlay      : yes
      buttons      :
        Ok         :
          title    : 'OK'
          style    : 'GenericButton'
          callback : -> modal.destroy()


  drop: (event) ->

    super

    { files, items }  = event.originalEvent.dataTransfer

    if files.length >= 20
      @showGenericError()
      return

    if items?[0].webkitGetAsEntry?

      for item in items
        entry = item.webkitGetAsEntry()

        return  unless entry  # Fix for Chrome OS / Chromium

        if entry.isDirectory
          @walkDirectory entry.filesystem.root, (file) =>
            # upload walked file
            @uploadFiles [file], event
          , =>
            # fallback for file upload, upload the other files stack
            @uploadFiles files, event
        else if entry.isFile
          entry.file (file) =>
            # upload file entry
            @uploadFiles [file], event

    else

      for file in files
        if file.type is ''
          @showGenericError() # "Folder upload is only supported for Chrome 21+"
          return

      # fallback to upload files for folder upload browsers
      @uploadFiles files, event


  uploadFiles: (files, event) ->

    @_uploaded or= {}

    if files?.length

      lastFile = files.last

      for file, index in files

        sizeInMb = file.size / 1024 / 1024
        if sizeInMb > 100 and @getOptions().uploadToVM
          notify_ 'Too big file to upload.', 'error', 'Max 100MB allowed per file.'
          continue

        reader = new FileReader
        reader.onloadend = do (file = files[index]) => (readEvent) =>

          fileName = file.fileName or file.name

          if file.relativePath
            return if @_uploaded[file.relativePath + fileName]
            @_uploaded[file.relativePath + fileName] = yes

          if @getOptions().uploadToVM
            fsFile = @upload fileName, readEvent.target.result, file.relativePath

          @emit 'dropFile',
            origin  : 'external'
            filename: fileName
            path    : file.relativePath or no
            instance: fsFile
            content : readEvent.target.result
            isLast  : file is lastFile
          , event, readEvent

          @reset()  if file is lastFile

        reader.readAsBinaryString file

    else

      internalData = event.originalEvent.dataTransfer.getData 'Text'
      return  unless internalData

      multipleItems = internalData.split ','
      lastItem = multipleItems.last
      for item in multipleItems
        { basename } = getPathInfo item
        fsFile = FSHelper.createFileInstance { path: item }
        @emit 'dropFile',
          origin  : 'internal'
          filename: basename
          instance: fsFile
          content : null
          isLast  : item is lastItem
        , event, no

        @reset() if item is lastItem

  walkDirectory: (dirEntry, callback, error) ->

    dirReader = dirEntry.createReader()
    relative  = FSHelper.convertToRelative dirEntry.fullPath

    dirReader.readEntries (entries) =>

      if entries.length > 20
        @showGenericError() # "It's not allowed to upload more than 20 files at once."
        return

      for entry in entries
        if entry.isFile
          entry.file (file) ->
            file.relativePath = relative # + file.name
            callback file
        else
          @walkDirectory entry, callback, error

    , error

  setPath: (path) ->

    { uploadToVM, defaultPath, title } = @getOptions()

    @path = path or defaultPath or "/home/#{nick()}/Uploads"

    @updatePartial """
      <div class="file-drop">
        #{title or "Drop files here!"}
        <small>#{if uploadToVM then (FSHelper.getVMNameFromPath(@path) or '') else ''}</small>
        <small>#{if uploadToVM then FSHelper.plainPath @path else ''}</small>
      </div>
    """
    @showCancel()
    if uploadToVM and @finder
      @finder.expandFolders @path

  showCancel: ->
    @addSubView new KDCustomHTMLView
      tagName   : 'a'
      partial   : 'cancel'
      cssClass  : 'cancel'
      attributes: { href: '#' }
      click     : => @emit 'cancel'

  saveFile: (fsFile, data) ->

    filePath   = "[#{fsFile.machine.uid}]#{fsFile.path}"
    parentPath = "[#{fsFile.machine.uid}]#{fsFile.parentPath}"

    fsFile.save '', => @emit 'uploadComplete', { filePath, parentPath }

    fsFile.saveBinary data, (err, res, progress) =>

      kd.log 'Upload result:', err, res, progress

      progress or= res
      return if err
      if res.finished
        @emit 'uploadEnd', fsFile
      else if res.abort
        @emit 'uploadAbort', fsFile
      else
        @emit 'uploadProgress', { file: fsFile, progress }


  upload: (fileName, contents, relativePath) ->

    machine = @getMachine()
    folder  = if relativePath and relativePath isnt fileName
    then "#{@path}/#{relativePath}"
    else @path

    modalStack   = KDModalView.createStack { lastToFirst: yes }
    fsFolderItem = FSHelper.createFileInstance { path: folder, type: 'folder', machine }
    fsFileItem   = FSHelper.createFileInstance { path: "#{folder}/#{fileName}", machine }

    return if FSHelper.isUnwanted fsFolderItem.path
    return if FSHelper.isUnwanted fsFileItem.path, yes

    upload = =>

      fsFileItem.exists (err, exists) =>

        if not exists or fsFileItem.getLocalFileInfo().lastUploadedChunk?

          @saveFile fsFileItem, contents

        else

          modalStack.addModal modal = new ContentModal
            cssClass : 'content-modal'
            overlay : no
            title : 'Overwrite File?'
            content : """
              <p>
                You already have the file <strong>#{fsFileItem.path}</strong>. Do you want
                to overwrite it?
              </p>
            """
            buttons :
              'cancel all' :
                title : 'CANCEL ALL'
                cssClass : 'kdbutton solid medium cancel'
                callback : -> modalStack.destroy()
              cancel :
                title : 'CANCEL'
                attributes : { style : 'margin-left : 10px' }
                cssClass : 'kdbutton solid medium cancel'
                callback : -> modal.destroy()
              overwrite :
                title : 'OVERWRITE'
                cssClass : 'kdbutton GenericButton'
                callback : =>
                  @saveFile fsFileItem, contents
                  modal.destroy()


    fsFolderItem.exists (err, exists) ->

      return if  showError err

      if exists
      then do upload
      else
        FSItem.create {
          path      : fsFolderItem.path
          type      : 'folder'
          recursive : yes
          machine
        } , (err) ->
          do upload  unless showError err

    return fsFileItem

  getMachine: ->

    @getDelegate().machines.first.machine
