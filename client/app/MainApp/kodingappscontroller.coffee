@KDApps = {}

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
              KodingAppsController.apps["#{app.name}"] = app
            log KodingAppsController.apps
            callback? KodingAppsController.apps

  addScript:(app, scriptInput, callback)->
    
    if /^\.\//.test scriptInput
      @getSingleton("kiteController").run
        withArgs  : 
          command : "cat #{@getAppPath app}/#{scriptInput}"
      , (err, response)=>
        if err then warn err
        callback err, "#{response}"
    else
      callback null, "#{scriptInput}"
  
  getAppPath:(app)->

    {profile} = KD.whoami()
    if /^~/.test app.path
      path = "/Users/#{profile.nickname}#{app.path.substr(1)}"
    else
      path = app.path

    path += "/" unless path[path.length-1] is "/"
    
    return path
  
  saveCompiledApp:(app, script)->
    

    @getSingleton("kiteController").run
      toDo        : "uploadFile"
      withArgs    : {
        path      : FSHelper.escapeFilePath "#{@getAppPath app}index.js"
        contents  : script
      }
    , (err, response)=>
      if err then warn err
      log err, response, "<<<<<<"
  
  defineApp:(app, script)->
    
    KDApps[app.name] = 
      """
      (function() {
      #{script}
      }).call(appView);
      """

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
          asyncStack.push (callback)=> @addScript app, block.pre, callback
          
        # log ">>>>>>> processing block named #{block.name} <<<<<<<<"
        if block.files
          {files} = block
          files.forEach (file, index)=>
            if "object" is typeof file
              for fileName, fileExtras of file
                do =>
                  # log fileExtras.pre  if fileExtras.pre
                  if fileExtras.pre
                    asyncStack.push (callback)=> @addScript app, fileExtras.pre, callback 
                  # log fileName
                  asyncStack.push (callback)=> @addScript app, fileName, callback
                  # log fileExtras.post if fileExtras.post
                  if fileExtras.post
                    asyncStack.push (callback)=> @addScript app, fileExtras.post, callback
            else
              # log file
              asyncStack.push (callback)=> @addScript app, file, callback
        # log block.post if block.post
        if block.post
          asyncStack.push (callback)=> 
            @addScript app, block.post, callback

      async.parallel asyncStack, (error, result)=>
        
        _final = "/* KDAPP STARTS */"
        result.forEach (output)=>
          _final += "\n\n/* BLOCK STARTS */\n\n"
          _final += "#{output}"
          _final += "\n\n/* BLOCK ENDS */\n\n"
        _final += "/* KDAPP ENDS */"
        
        @saveCompiledApp app, _final
        @defineApp app, _final

    unless KodingAppsController.apps[name]
      @fetchApps (apps)=> kallback apps[name]
    else
      kallback KodingAppsController.apps[name]