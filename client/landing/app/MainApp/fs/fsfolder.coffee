
class FSFolder extends FSFile

  fetchContents:(callback)->

    {nickname} = KD.whoami().profile

    @emit "fs.job.started"
    @kiteController.run
      kiteName   : 'os'
      method     : 'fs.readDirectory'
      withArgs   :
        onChange : (change)=>
          FSHelper.folderOnChange @path, change, @treeController
        path     : @path
    , (err, response)=>
      if not err and response?.files
        files = FSHelper.parseWatcher @path, response.files
        {@stopWatching} = response
        @emit "fs.job.finished", err, files
      else
        @emit "fs.job.finished", err
      callback? err, files

  save:(callback)->

    @emit "fs.save.started"

    @kiteController.run
      kiteName  : 'os'
      method    : 'fs.createDirectory'
      withArgs  : {@path}
    , (err, res)=>

      if err then warn err
      @emit "fs.save.finished", err, res
      callback? err, res

  saveAs:(callback)->
    log 'Not implemented yet.'
    callback? null

  remove:(callback)->
    super callback, yes