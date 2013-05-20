class FSFolder extends FSFile

  fetchContents:(callback, dontWatch=yes)->

    {nickname} = KD.whoami().profile

    @emit "fs.job.started"
    @kiteController.run
      kiteName   : 'os'
      method     : 'fs.readDirectory'
      vmName     : @vmName
      withArgs   :
        onChange : if dontWatch then null else (change)=>
          FSHelper.folderOnChange @vmName, @path, change, @treeController
        path     : FSHelper.plainPath @path
    , (err, response)=>
      if not err and response?.files
        files = FSHelper.parseWatcher @vmName, @path, response.files
        @registerWatcher response
        @emit "fs.job.finished", err, files
      else
        @emit "fs.job.finished", err
      callback? err, files

  save:(callback)->

    @emit "fs.save.started"

    @kiteController.run
      kiteName  : 'os'
      vmName    : @getData().vmName
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
      finder = KD.getSingleton 'finderController'
      finder.stopWatching @path

    super callback, yes

  registerWatcher:(response)->
    {@stopWatching} = response
    finder = KD.getSingleton 'finderController'
    finder.registerWatcher @path, @stopWatching  if @stopWatching