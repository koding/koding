class FSFile extends FSItem

  constructor:->
    super

    @on "file.requests.saveAs", (contents, name, parentPath)=>
      @saveAs contents, name, parentPath

    @on "file.requests.save", (contents)=>
      @save contents

  fetchContents:(callback)->

    @emit "fs.fetchContents.started"
    @kiteController.run
      kiteName  : 'os'
      method    : 'fs.readFile'
      withArgs  : {@path}
    , (err, response)=>

      if err then warn err
      else
        {content} = response

        # Convert to String
        content = atob content

      callback.call @, err, content
      @emit "fs.fetchContents.finished", err, content

  saveAs:(contents, name, parentPath, callback)->

    oldPath = @path
    newPath = "#{parentPath}/#{name}"
    @emit "fs.saveAs.started"

    FSHelper.ensureNonexistentPath "#{newPath}", (err, response)=>
      if err
        callback? err, response
        warn err
      else
        newFile = FSHelper.createFileFromPath response
        newFile.save contents, (err, res)=>
          if err then warn err
          else
            @emit "fs.saveAs.finished", newFile, @

  save:(contents, callback)->

    # if FSHelper.isEscapedPath @path
    #   @path = FSHelper.unescapeFilePath @path

    @emit "fs.save.started"

    # Convert to base64
    content = btoa contents

    @kiteController.run
      kiteName  : 'os'
      method    : 'fs.writeFile'
      withArgs  : {@path, content}
    , (err, res)=>

      if err then warn err
      @emit "fs.save.finished", err, res
      callback? err,res
