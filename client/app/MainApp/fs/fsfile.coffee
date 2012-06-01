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
        command : "cat #{@path}"
    , (err, response)=>
      if err then warn err
      callback.call @, err, response
      @emit "fs.fetchContents.finished", err, response


  saveAs:(contents, name, parentPath, callback)->
    
    oldPath = @path
    FSItem.getSafePath "#{parentPath}/#{name}", (err, response)=>
      if err
        callback? err, response
        warn err
      else
        @path       = response
        @parentPath = parentPath
        @name       = response.split('/').pop()
        @save contents
        @once "fs.save.finished", (err, res)=>
          if err then warn err
          else
            FSItem.emit "fs.remotefile.created", @
            @emit "fs.remotefile.created", oldPath
        

  save:(contents, callback)->

    @emit "fs.save.started"
    @kiteController.run
      toDo        : "uploadFile"
      withArgs    : {
        path      : FSHelper.escapeFilePath @path
        contents
      }
    , (err, res)=>
      @emit "fs.save.finished", err, res
      if err then warn err
      callback? err,res

  getExtension:->
    [root, rest..., extension]  = @path.split '.'
    extension or= ''


    