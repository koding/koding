class FSFile extends FSItem

  constructor:->
    super

    @on "file.requests.saveAs", (contents, name, parentPath)=>
      @saveAs contents, name, parentPath

    @on "file.requests.save", (contents)=>
      @save contents

  fetchContents:(callback)->

    @emit "fs.job.started"
    @kiteController.run
      kiteName  : 'os'
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

    newPath = FSHelper.plainPath "#{parentPath}/#{name}"
    @emit "fs.saveAs.started"

    FSHelper.ensureNonexistentPath "#{newPath}", @vmName, (err, response)=>
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

    @emit "fs.save.started"

    # Convert to base64
    content = btoa KD.utils.utf8Encode contents

    @kiteController.run
      kiteName  : 'os'
      method    : 'fs.writeFile'
      vmName    : @vmName
      withArgs  :
        path    : FSHelper.plainPath @path
        content : content
    , (err, res)=>

      if err then warn err
      @emit "fs.save.finished", err, res
      callback? err,res
