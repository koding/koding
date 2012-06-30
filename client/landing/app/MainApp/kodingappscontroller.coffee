@KDApps = {}

class KodingAppsController extends KDController

  @apps = {}

  constructor:->

    super

  fetchApps:(callback)->
    
    # log Object.keys(KodingAppsController.apps).length, ">>>>>"
    # 
    if Object.keys(KodingAppsController.apps).length is 0

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
                KodingAppsController.apps["#{app.name}"] = app

              callback? KodingAppsController.apps

    else
      
      callback? KodingAppsController.apps

  addScript:(app, scriptInput, callback)->
    
    if /^\.\//.test scriptInput
      @getSingleton("kiteController").run
        withArgs  : 
          command : "cat #{@getAppPath app}/#{scriptInput}"
      , (err, response)=>
        if err then warn err
        
        if /.coffee$/.test scriptInput
          require ["coffee-script"], (coffee)->
            js = coffee.compile response, { bare : yes }
            callback err, js
        else
          callback err, response
    else
      callback null, scriptInput
  
  getAppPath:(app)->

    {profile} = KD.whoami()
    if /^~/.test app.path
      path = "/Users/#{profile.nickname}#{app.path.substr(1)}"
    else
      path = app.path

    path += "/" unless path[path.length-1] is "/"
    
    return path
  
  saveCompiledApp:(app, script, callback)->
    

    @getSingleton("kiteController").run
      toDo        : "uploadFile"
      withArgs    : {
        path      : FSHelper.escapeFilePath "#{@getAppPath app}index.js"
        contents  : script
      }
    , (err, response)=>
      if err then warn err
      log err, response, "<<<<<<"
      callback?()
  
  defineApp:(app, script)->
    
    KDApps[app.name] = script

    # KDApps[app.name] = 
    #   """
    #   (function(appView) {
    #   #{script}
    #   }).call(appView);
    #   """
  
  getApp:(name, callback)->
    kallback = =>
      callback?()
    
    if KDApps[name]
      callback KDApps[name]
    else
      @compileSource name, =>
        callback KDApps[name]
  
  compileSource:(name, callback)->

    log "ever compileSource"
    
    
    kallback = (app)=>
      
      log "ever kallback"
      
      return warn "#{name}: No such app!" unless app

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
          asyncStack.push (cb)=> @addScript app, block.pre, cb
          
        # log ">>>>>>> processing block named #{block.name} <<<<<<<<"
        if block.files
          {files} = block
          files.forEach (file, index)=>
            if "object" is typeof file
              for fileName, fileExtras of file
                do =>
                  # log fileExtras.pre  if fileExtras.pre
                  if fileExtras.pre
                    asyncStack.push (cb)=> @addScript app, fileExtras.pre, cb 
                  # log fileName
                  asyncStack.push (cb)=> @addScript app, fileName, cb
                  # log fileExtras.post if fileExtras.post
                  if fileExtras.post
                    asyncStack.push (cb)=> @addScript app, fileExtras.post, cb
            else
              # log file
              asyncStack.push (cb)=> @addScript app, file, cb
        # log block.post if block.post
        if block.post
          asyncStack.push (cb)=> @addScript app, block.post, cb

      async.parallel asyncStack, (error, result)=>
        
        log "ever async"
        
        final = "(function() {\n\n/* KDAPP STARTS */"
        result.forEach (output)=>
          final += "\n\n/* BLOCK STARTS */\n\n"
          final += "#{output}"
          final += "\n\n/* BLOCK ENDS */\n\n"
        final += "/* KDAPP ENDS */\n\n}).call();"
        
        
        final = @defineApp app, final
        @saveCompiledApp app, final, =>
          callback?()

    unless KodingAppsController.apps[name]
      @fetchApps (apps)=> kallback apps[name]
    else
      kallback KodingAppsController.apps[name]