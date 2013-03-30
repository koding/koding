
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
        @emit "fs.fetchContents.finished", files
        callback? files
      else
        @emit "fs.fetchContents.finished", err

class FSFolderOld extends FSFile

  fetchContents:(callback)->

    @emit "fs.fetchContents.started"
    @kiteController.run
      withArgs  :
        command : "ls #{FSHelper.escapeFilePath @path} -Llpva --group-directories-first --time-style=full-iso"
    , (err, response)=>
      if not err or /ls\:\scannot\saccess/.test err.message
        files = FSHelper.parseLsOutput [@path], response
        @emit "fs.fetchContents.finished", files
        callback? files
      else
        @emit "fs.fetchContents.finished", err
