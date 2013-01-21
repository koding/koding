class FSFile extends FSItem

  constructor:->
    super
    @modified = no
    @_savedContents = ''

    @on "file.requests.saveAs", (contents, name, parentPath)=> @saveAs contents, name, parentPath
    @on "file.requests.save", (contents)=> @save contents

  fetchContents:(callback)->

    @emit "fs.fetchContents.started"
    @kiteController.run
      withArgs  :
        command : "cat #{FSHelper.escapeFilePath @path}"
    , (err, response)=>
      if err then warn err
      callback.call @, err, response
      @emit "fs.fetchContents.finished", err, response


  saveAs:(contents, name, parentPath, callback)->

    oldPath = @path
    newPath = "#{parentPath}/#{name}"
    @emit "fs.saveAs.started"
    FSItem.getSafePath "#{newPath}", (err, response)=>
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
    if FSHelper.isEscapedPath @path
      @path = FSHelper.unescapeFilePath @path

    @emit "fs.save.started"
    @kiteController.run
      method        : "uploadFile"
      withArgs    : {
        path      : FSHelper.escapeFilePath @path
        contents
      }
    , (err, res)=>
      @emit "fs.save.finished", err, res
      if err then warn err
      callback? err,res
