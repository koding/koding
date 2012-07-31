@KDApps = {}

class KodingAppsController extends KDController

  @apps = {}

  constructor:->

    super

  fetchApps:(callback)->
    
    @fetchAppsFromDb (err, apps)=>
      if err
        @fetchAppsFromFs (err, apps)=>
          if err then callback()
          else
            callback null, apps
      else
        callback? err, apps

  fetchAppsFromFs:(callback)->
    
    path = "/Users/#{KD.whoami().profile.nickname}/Applications"

    @getSingleton("kiteController").run
      withArgs  :
        command : "ls #{path} -lpva"
    , (err, response)=>
      if err 
        warn err
        callback err
      else
        files = FSHelper.parseLsOutput [path], response
        apps  = []
        stack = []

        files.forEach (file)->
          if /\.kdapp$/.test file.name
            apps.push file
    
        apps.forEach (app)->
          manifest = if app.type is "folder" then FSHelper.createFileFromPath "#{app.path}/.manifest" else app
          stack.push (cb)->
            manifest.fetchContents cb
    
        async.parallel stack, (err, results)=>
          if err
            warn err
            callback? err
          else
            results.forEach (app)->
              app = JSON.parse app
              KodingAppsController.apps["#{app.name}"] = app
            callback? err, KodingAppsController.apps

  fetchAppsFromDb:(callback)->

    appManager.fetchStorage "KodingApps", "1.0", (err, storage)=>
      if err 
        warn err
        callback err
      else
        apps = storage.getAt "bucket.apps"
        if apps and Object.keys(apps).length > 0
          KodingAppsController.apps = apps
          callback null, apps
        else
          callback new Error "There are no apps in the app storage."

  putAppsToAppStorage:(apps)->

    appManager.fetchStorage "KodingApps", "1.0", (err, storage)->
      storage.update {
        $set: { "bucket.apps" : apps }
      }, => log arguments,"kodingAppsController storage updated"

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
      log response, "App saved!"
      callback?()
  
  publishApp:(appName, callback)->

    kiteController = @getSingleton('kiteController')
    @getApp appName, (appScript)=>

      manifest    = KodingAppsController.apps[appName]
      {nickname}  = KD.whoami().profile
      publishPath = FSHelper.escapeFilePath "/opt/Apps/#{nickname}/#{manifest.name}/#{manifest.version}"
      userAppPath = if /~\//.test manifest.path
        manifest.path.replace("~/", "/Users/#{nickname}/") + "index.js"
      else 
        "#{manifest.path}/index.js"
      options     =
        toDo          : "publishApp"
        withArgs      :
          version     : manifest.version
          appName     : manifest.name
          userAppPath : userAppPath

      kiteController.run options, (err, res)=>
        log "app is being published"
        if err then warn err
        else
          jAppData =
            title       : manifest.name or "Application Title"
            body        : manifest.description or "Application description"
            manifest    : manifest
          appManager.tell "Apps", "createApp", jAppData, (err, app)=>
            log app, "app published"
            appManager.openApplication "Apps", yes, (instance)=>
              # instance.feedController.changeActiveSort "meta.modifiedAt"
              callback?()


  defineApp:(app, script)->
    
    KDApps[app.name] = script
  
  getApp:(name, callback = noop)->

    if KDApps[name]
      callback KDApps[name]
    else
      @compileSource name, =>
        callback KDApps[name]
  
  compileSource:(name, callback)->

    # log "ever compileSource"
    
    
    kallback = (app)=>
      
      # log "ever kallback"
      
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
        
        log "concatenating the app"
        
        _final = "(function() {\n\n/* KDAPP STARTS */"
        result.forEach (output)=>
          _final += "\n\n/* BLOCK STARTS */\n\n"
          _final += "#{output}"
          _final += "\n\n/* BLOCK ENDS */\n\n"
        _final += "/* KDAPP ENDS */\n\n}).call();"
        
        
        _final = @defineApp app, _final
        @saveCompiledApp app, _final, =>
          callback?()

    unless KodingAppsController.apps[name]
      @fetchApps (err, apps)=> kallback apps[name]
    else
      kallback KodingAppsController.apps[name]