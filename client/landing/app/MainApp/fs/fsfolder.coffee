
class FSFolder extends FSFile

  fetchContents:(callback)->

    {nickname} = KD.whoami().profile
    @emit "fs.fetchContents.started"
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
        @emit "fs.fetchContents.finished", files
        callback? files
      else
        @emit "fs.fetchContents.finished", err
