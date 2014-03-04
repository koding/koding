class FSFolder extends FSFile

  fetchContents:(callback, dontWatch=yes)->
    { treeController } = @getOptions()

    @emit "fs.job.started"
    @vmController.run
      method     : 'fs.readDirectory'
      vmName     : @vmName
      withArgs   :
        onChange : if dontWatch then null else (change)=>
          FSHelper.folderOnChange @vmName, @path, change, treeController
        path     : FSHelper.plainPath @path
    , (err, response)=>
      if not err and response?.files
        files = FSHelper.parseWatcher @vmName, @path, response.files, treeController
        @registerWatcher response
        @emit "fs.job.finished", err, files
      else
        @emit "fs.job.finished", err
      callback? err, files

  save:(callback)->

    @emit "fs.save.started"

    @vmController.run
      vmName    : @vmName
      method    : 'fs.createDirectory'
      withArgs  :
        path    : FSHelper.plainPath @path
    , (err, res)=>
      if err then warn err
      @emit "fs.save.finished", err, res
      callback? err, res

  saveAs:(callback)->
    log 'Not implemented yet.'
    callback? null

  remove:(callback)->
    @off 'fs.delete.finished'
    @on  'fs.delete.finished', =>
      finder = @treeController.delegate
      finder?.stopWatching @path

    super callback, yes

  registerWatcher:(response)->
    {@stopWatching} = response
    finder = @treeController.delegate
    finder?.registerWatcher @path, @stopWatching  if @stopWatching