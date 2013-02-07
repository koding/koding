class FSFolder extends FSFile

  fetchContents:(callback)->

    # @emit "fs.fetchContents.started"
    # @kiteController.run
    #   method      : "ls"
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
      if not err or /ls\:\scannot\saccess/.test err.message
        files = FSHelper.parseLsOutput [@path], response
        @emit "fs.fetchContents.finished", files
        callback? files
      else
        @emit "fs.fetchContents.finished", err

  # forkRepoCommandMap = ->

  #   git : "git clone"
  #   svn : "svn checkout"
  #   hg  : "hg clone"

  # cloneRepo:(options, callback)->

  #   @kiteController.run "#{forkRepoCommandMap()[repoType]} #{repo} #{escapeFilePath getAppPath manifest}", (err, response)->
