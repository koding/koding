class FSFolder extends FSFile

  fetchContents:(callback)->

    # @emit "fs.fetchContents.started"
    # @kiteController.run
    #   toDo      : "ls"
    #   withArgs  :
    #     command : @path
    # , (err, response)=>
    #   if err
    #     warn err
    #     @emit "fs.fetchContents.finished", err
    #   else
    #     files = FSHelper.parseLsOutput [@path], response
    #     @emit "fs.fetchContents.finished", files
    #     callback? files


    @emit "fs.fetchContents.started"
    # a = Date.now()
    @kiteController.run
      withArgs  :
        command : "ls #{FSHelper.escapeFilePath @path} -Llpva --group-directories-first --time-style=full-iso"
    , (err, response)=>
      # log "------------------------------------------------------------------"
      # log "l flag response in: #{Date.now()-a} msec."
      if err
        warn err
        @emit "fs.fetchContents.finished", err
      else
        files = FSHelper.parseLsOutput [@path], response
        @emit "fs.fetchContents.finished", files
        callback? files
