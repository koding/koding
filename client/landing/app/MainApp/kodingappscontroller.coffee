class KodingAppsController extends KDController

  @apps = {}

  constructor:->

    super

  fetchApps:(callback)->
    
    path = "/Users/#{KD.whoami().profile.nickname}/Applications"
    
    @getSingleton("kiteController").run
      withArgs  :
        command : "ls #{path} -lpva"
    , (err, response)=>
      if err 
        warn err
      else
        files = FSHelper.parseLsOutput [path], response
        apps  = []
        stack = []
        for file in files
          if /\.kdapp$/.test file.name
            apps.push file
        
        apps.forEach (app)->
          manifest = if app.type is "folder" then FSHelper.createFileFromPath "#{app.path}/.manifest" else app
          stack.push (cb)->
            manifest.fetchContents cb
        
        async.parallel stack, (err, results)=>
          if err then warn err else
            results.forEach (app)->
              app = JSON.parse app
              KodingAppsController.apps["#{app.name}-#{app.version}"] = app
            log KodingAppsController.apps
            callback? KodingAppsController.apps

  addScript:(scriptInput, callback)->
    
    log scriptInput, ">>>>>"
    
    if /^\.\//.test scriptInput
      @getSingleton("kiteController").run
        withArgs  : 
          command : "cat /Users/sinan/Applications/Ace.kdapp/src/#{scriptInput}"
      , (err, response)=>
        if err then warn err
        callback err, "#{response}"
    else
      callback null, "#{scriptInput}"
  
  saveCompiledApp:(script)->
    
    log FSHelper.escapeFilePath "/Users/sinan/Applications/Ace.kdapp/index.js"
    
    @getSingleton("kiteController").run
      toDo        : "uploadFile"
      withArgs    : {
        path      : FSHelper.escapeFilePath "/Users/sinan/Applications/Ace.kdapp/index.js"
        contents  : script
      }
    , (err, response)=>
      if err then warn err
      log err, response, "<<<<<<"

  compileSource:(name)->
    
    kallback = (app)=>

      return warn "No such app!" unless app

      {source} = app
      {blocks} = source
      
      orderedBlocks = []
      for blockName, blockOptions of blocks
        blockOptions.name = blockName
        if blockOptions.order? and not isNaN(order = parseInt(blockOptions.order, 10))
          orderedBlocks[order] = blockOptions
        else
          orderedBlocks.push blockOptions
      
      blockStrings = []
      
      asyncStack   = []

      orderedBlocks.forEach (block)=>
        # log block.pre  if block.pre
        if block.pre
          asyncStack.push (callback)=> @addScript block.pre, callback
          
        # log ">>>>>>> processing block named #{block.name} <<<<<<<<"
        if block.files
          {files} = block
          files.forEach (file, index)=>
            if "object" is typeof file
              for fileName, fileExtras of file
                do =>
                  # log fileExtras.pre  if fileExtras.pre
                  if fileExtras.pre
                    asyncStack.push (callback)=> @addScript fileExtras.pre, callback 
                  # log fileName
                  asyncStack.push (callback)=> @addScript fileName, callback
                  # log fileExtras.post if fileExtras.post
                  if fileExtras.post
                    asyncStack.push (callback)=> @addScript fileExtras.post, callback
            else
              # log file
              asyncStack.push (callback)=> @addScript file, callback
        # log block.post if block.post
        if block.post
          asyncStack.push (callback)=> 
            @addScript block.post, callback

      async.parallel asyncStack, (error, result)=>
        
        final = ""
        result.forEach (output)=>
          final += "#{output}"
          final += "\n\n/*-------------------------------------------------------*/\n\n"
        
        @saveCompiledApp final
          
        

    unless KodingAppsController.apps[name]
      @fetchApps (apps)=> kallback apps[name]
    else
      kallback KodingAppsController.apps[name]