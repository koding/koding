class FSFile extends FSItem

  constructor:->
    super

    @on "file.requests.saveAs", (contents, name, parentPath)=>
      @saveAs contents, name, parentPath

    @on "file.requests.save", (contents)=>
      @save contents

    @localStorage = KD.getSingleton("localStorageController").storage "Finder"
    @fileInfo     = @getLocalFileInfo()

  getLocalFileInfo: ->
    @localStorage.getValue(btoa FSHelper.plainPath @path) or {}

  setLocalFileInfo: (data={})->
    @fileInfo[key] = value for own key, value of data
    @localStorage.setValue btoa(FSHelper.plainPath @path), @fileInfo

  removeLocalFileInfo: ->
    @localStorage.unsetKey btoa FSHelper.plainPath @path

  fetchContentsBinary: (callback)->
    @fetchContents callback, no

  fetchContents:(callback, useEncoding=yes)->

    @emit "fs.job.started"
    @vmController.run
      method    : 'fs.readFile'
      vmName    : @vmName
      withArgs  :
        path    : FSHelper.plainPath @path
    , (err, response)=>

      if err then warn err
      else
        content = atob response.content

        if useEncoding
          content = KD.utils.utf8Decode content # Convert to String

      callback.call @, err, content
      @emit "fs.job.finished", err, content

  saveAs:(contents, name, parentPath, callback)->

    @vmName = FSHelper.getVMNameFromPath parentPath  if parentPath
    newPath = FSHelper.plainPath "#{parentPath}/#{name}"
    @emit "fs.saveAs.started"

    FSHelper.ensureNonexistentPath "#{newPath}", @vmName, (err, path)=>
      if err
        callback? err, path
        warn err
      else
        newFile = FSHelper.createFile
          type   : 'file'
          path   : path
          vmName : @vmName
        newFile.save contents, (err, res)=>
          if err then warn err
          else
            @emit "fs.saveAs.finished", newFile, @

  append: (contents, callback)->
    @emit "fs.append.started"

    # Convert to base64
    content = btoa contents

    @vmController.run
      method    : 'fs.writeFile'
      vmName    : @vmName
      withArgs  :
        path    : FSHelper.plainPath @path
        content : content
        append  : yes
    , (err, res)=>

      if err then warn err
      @emit "fs.append.finished", err, res
      callback? err,res

  @createChunkQueue: (data, chunkSize=1024*1024, skip=0)->

    return unless data

    chunks     = FSHelper.chunkify data, chunkSize
    queue      = []

    for chunk, index in chunks
      isSkip = skip > index
      queue.push
        content : unless isSkip then btoa chunk
        skip    : isSkip
        append  : yes if queue.length > 0 # first chunk is not an append

    return queue

  # TODO: This method has too many logic with chunks etc. should be retought later. -- fka
  saveBinary:(contents, callback)->

    @abortRequested     = no
    info                = @getLocalFileInfo()
    chunkQueue          = FSFile.createChunkQueue contents, null, info.lastUploadedChunk
    total               = chunkQueue.length

    @setLocalFileInfo totalChunks: total

    iterateChunks = =>
      next = chunkQueue.shift()
      return unless next

      if next.skip
        callback null, {},
          percent: 100 * info.lastUploadedChunk / info.totalChunks
        iterateChunks()
        return

      @vmController.run
        method    : 'fs.writeFile'
        vmName    : @vmName
        withArgs  :
          path    : FSHelper.plainPath @path
          content : next.content
          append  : next.append
      , (err, res) =>

        return callback? err  if err

        @setLocalFileInfo lastUploadedChunk: total - chunkQueue.length

        if @abortRequested
          @abortRequested = no # reset the state
          callback? null, abort: yes
          return

        loaded   = total - chunkQueue.length
        percent  = 100 * loaded / total

        callback? null, res, {total, loaded, percent}
        iterateChunks()
        if chunkQueue.length is 0 # finished all the chunks
          callback? null, finished: yes
          @removeLocalFileInfo()

    iterateChunks() if chunkQueue.length > 0

  abort: ->
    @abortRequested = yes

  save:(contents, callback, useEncoding=yes)->

    @emit "fs.save.started"

    if useEncoding
      contents = KD.utils.utf8Encode contents

    # Convert to base64
    content = btoa contents

    @vmController.run
      method    : 'fs.writeFile'
      vmName    : @vmName
      withArgs  :
        path    : FSHelper.plainPath @path
        content : content
    , (err, res)=>

      if err then warn err
      @emit "fs.save.finished", err, res
      callback? err,res
