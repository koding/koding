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
    @localStorage.getValue(btoa KD.utils.utf8Encode FSHelper.plainPath @path) or {}

  setLocalFileInfo: (data={})->
    @fileInfo[key] = value for own key, value of data
    @localStorage.setValue btoa(KD.utils.utf8Encode FSHelper.plainPath @path), @fileInfo

  removeLocalFileInfo: ->
    @localStorage.unsetKey btoa KD.utils.utf8Encode FSHelper.plainPath @path

  fetchContentsBinary: (callback)->
    @fetchContents no, callback

  fetchRawContents: (callback)->

    kite = @getKite()
    kite.vmOn().then =>
      kite.fsReadFile path: FSHelper.plainPath @path
    .nodeify callback

  fetchContents: (useEncoding, callback)->
    [callback, useEncoding] = [useEncoding, callback]  unless callback

    useEncoding ?= yes

    @emit "fs.job.started"

    @fetchRawContents().then (response)=>

      content = atob response.content
      content = KD.utils.utf8Decode content  if useEncoding # Convert to String

      KD.mixpanel "Fetch contents, success"

      @emit "fs.job.finished"

      return content

    .nodeify(callback)



  saveAs:(contents, name, parentPath, callback)->
    @emit "fs.saveAs.started"

    newPath = FSHelper.plainPath "#{parentPath}/#{name}"

    file = null

    kite = @getKite()

    kite.vmOn()
    .then =>

      ok = kite.fsUniquePath(path: "#{newPath}")
      .then (actualPath) =>

        file = FSHelper.createFileInstance {
          type   : 'file'
          path   : actualPath
          @machine
        }

        ok = file.save contents

        if callback?

          ok = ok
          .catch (err) ->
            callback err

          .then (response) =>
            callback null, file, this

        ok

      .then (response) =>
        @emit "fs.saveAs.finished", file, this

        return file

  append: (contents, callback)->
    @emit "fs.append.started"

    # Convert to base64
    content = btoa contents

    kite = @getKite()

    ok = kite.startVm()
    .then =>

      kite.fsWriteFile {
        path    : FSHelper.plainPath @path
        content : btoa contents
        append  : yes
      }

    if callback?
      ok
      .then (response) =>
        callback null, response
        @emit 'fs.append.finished', null, response

      .catch (err) ->
        warn err
        callback err
        @emit 'fs.append.finished', err

    else
      ok
      .then (response) =>
        @emit 'fs.append.finished', null, response
        Promise.cast response

  @createChunkQueue: (data, chunkSize=1024*1024, skip=0)->

    return unless data

    chunks     = FSHelper.chunkify data, chunkSize
    queue      = []

    for chunk, index in chunks
      isSkip = skip > index
      queue.push
        content : unless isSkip then btoa chunk
        skip    : isSkip
        append  : queue.length > 0 # first chunk is not an append

    return queue

  saveBinary:(contents, callback)->

    info       = @getLocalFileInfo()
    chunkQueue = FSFile.createChunkQueue contents, null, info.lastUploadedChunk
    total      = chunkQueue.length

    @setLocalFileInfo totalChunks: total

    @on "ChunkUploaded", (response)=>
      loaded   = total - chunkQueue.length
      percent  = 100 * loaded / total
      @setLocalFileInfo lastUploadedChunk: loaded
      callback? null, response, {total, loaded, percent}

    @once "AllChunksUploaded", =>
      @off "ChunkUploaded"
      @removeLocalFileInfo()
      callback? null, finished: yes

    @once "AbortRequested", =>
      @abortRequested = yes
      callback? null, abort: yes

    iterateChunks = =>

      unless chunkQueue.length
        @emit "AllChunksUploaded"

      next = chunkQueue.shift()
      return unless next
      return if @abortRequested

      {skip, content, append} = next

      if skip
        callback null, {},
          percent: 100 * info.lastUploadedChunk / info.totalChunks
        iterateChunks()
        return

      @vmController.run
        method   : 'fs.writeFile'
        vmName   : @vmName
        withArgs : {path: FSHelper.plainPath(@path), content, append}
      , (err, res) =>
        return callback? err  if err
        @emit "ChunkUploaded", res
        iterateChunks()

    iterateChunks() if chunkQueue.length > 0

  abort: -> @emit "AbortRequested"

  save: (contents = '', callback = null, useEncoding = yes) ->

    @emit "fs.save.started"

    ok = @getKite().vmOn()
    .then =>

      contents = KD.utils.utf8Encode contents  if useEncoding

      # Convert to base64
      content = btoa contents

      @getKite().fsWriteFile {
        path: FSHelper.plainPath @path
        content
      }

    if callback?

      ok
      .then (response) =>
        callback null, response
        @emit "fs.save.finished", null, response

      .catch (err) =>
        callback err
        @emit "fs.save.finished", err

    else
      ok
      .then (response) =>
        @emit "fs.save.finished", null, response

        return response

