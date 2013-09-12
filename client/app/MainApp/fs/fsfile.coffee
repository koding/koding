class FSFile extends FSItem

  constructor:->
    super

    @on "file.requests.saveAs", (contents, name, parentPath)=>
      @saveAs contents, name, parentPath

    @on "file.requests.save", (contents)=>
      @save contents

    @localStorage = KD.getSingleton("localStorageController").storage "Finder"
    @lastChunk    = @localStorage.getAt("lastChunk-#{btoa @path}") or 0

  fetchContents:(callback)->

    @emit "fs.job.started"
    @vmController.run
      method    : 'fs.readFile'
      vmName    : @vmName
      withArgs  :
        path    : FSHelper.plainPath @path
    , (err, response)=>

      if err then warn err
      else
        {content} = response

        # Convert to String
        content = KD.utils.utf8Decode atob content

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

  saveBinary:(contents, callback)->

    @abortRequested     = no
    chunkSize           = 1024*1024
    chunks              = []
    runs                = []

    sendChunk = =>
      next = runs.shift()
      return unless next
      @vmController.run next, (err, res) =>
        return callback? err  if err

        if @abortRequested
          @abortRequested = no # reset the state
          callback? null, abort: yes
          if @abortResumable and runs.length > 0
            @localStorage.setAt "lastChunk-#{btoa @path}", runs.length
          return

        total    = chunks.length
        loaded   = chunks.length - runs.length
        percent  = 100 * loaded / total

        callback? null, res, {total, loaded, percent}
        sendChunk()
        if runs.length is 0 # finished all the chunks
          callback? null, finished: yes

    if runs.length is 0
      while contents
        if contents.length < chunkSize
          chunks.push contents
          break
        else
          chunks.push contents.substr 0, chunkSize
          contents = contents.substr chunkSize

      for chunk in chunks
        runs.push
          method    : 'fs.writeFile'
          vmName    : @vmName
          withArgs  :
            path    : FSHelper.plainPath @path
            content : btoa chunk
            append  : yes if runs.length > 0 # first chunk is not an append
        sendChunk() if chunks.length is runs.length
    else
      sendChunk()

  abort: (resumable=no)->
    @abortRequested = yes
    @abortResumable = resumable

  resume: ->
    return unless @localChunks is 0

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
