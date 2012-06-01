class Command extends KDObject
  constructor: (environment) ->
    super
    @setEnvironment environment if environment
    # @_registeredStartEvents = {}
    @setListeners()
    
  setListeners: ->
    # debugger
    events = [
      'multiLs'
      'fetchFile'
      'createFolder'
      'rename'
      'remove'
      'safePath'
      'extract'
      'compress'
      'saveFile'
      'createFile'
      'duplicate'
      'chmod'
      'stat'
      'move'
      'copy'
      'searchFile'
      'makePublic'
      ]
    
    for event in events
      do (event) =>
        @on "fs.#{event}.start", (data) =>
          @[event] data, (error, files) =>
            # log "MULTI LS BITTI EVENTI" if event is "multiLs"
            @emit "fs.#{event}.finish", error, data, files
  
  # ### maybe later...
  # on: (eventName, params) ->
  #   [fs, method, type] = eventName.split '.'
  #   unless @[method]
  #     warn "There is no method #{method} in commands"
  #     return
  #     
  #   log 'event', {fs, method, type}
  #   super eventName, params  #registering original event listener
  #   
  #   startEventName = "#{fs}.#{method}.start"
  #   
  #   unless @_registeredStartEvents[startEventName]
  #     @_registeredStartEvents[startEventName] = yes
  #     super startEventName, (data) => #starting listen for "start" events
  #       @[method] data, (error, respond) => #doing command by start event
  #         log "emitting #{fs}.#{method}.#{type}"
  #         @emit "#{fs}.#{method}.finish", error, data, respond #emitting results to requester
    
  # setEnvironment: (environment) ->
  #   @_environment = environment
  #   
  # getEnvironment: ->
  #   # @_environment
  #   Command._environment

  run: (options = {}, callback) ->
    kiteController = @getSingleton('kiteController')
    kiteController.run
      kiteName : options.kiteName or "sharedHosting"
      toDo     : options.toDo     or "executeCommand"
      withArgs : options.withArgs or {}
    , callback

    
  # searchFile:(options, callback) ->
  #   @getEnvironment().searchFile options, callback

  multiLs: ({dataItems, paths}, callback) ->
    # log "multiLs"
    # debugger
    stack   = ""
    stack   = stack + @escapeFilePath(path) for path in paths
    command = "ls #{stack}  -lpva --group-directories-first"
    options = withArgs : command : command
    
    @run options, (error, response) ->
      unless error?
        if paths
          files = CommandParser.parse paths, response
          callback error, files
        # else
        #   callback error, []
      else
        callback error, []
      
  fetchFile: ({path}, callback) ->
    path = @escapeFilePath path
    @run 
      withArgs  : 
        command : "cat #{path}"
    , callback
      
  createFile: ({path}, callback) ->
    @run 
      withArgs  : 
        command : "touch #{@escapeFilePath path}"
    , (error, response)->
      if error then warn error
      else
        file = CommandParser.createFile path, 'file'
      callback error, file

  createFolder: ({path}, callback) ->
    @run 
      withArgs  : 
        command : "mkdir #{@escapeFilePath path}"
    , (error, response)->
      if error then warn error
      else
        folder = CommandParser.createFile path, 'folder'
      callback error, folder
    
  saveFile: ({newFile, path}, callback) ->
    @run
      toDo        : "uploadFile"
      withArgs    : 
        path      : @escapeFilePath(newFile.path)
        contents  : newFile.contents
    , (error, res)=>
      if error 
        callback error 
      else 
        callback null,res

  duplicate: (data, callback) ->
    {fileData, path} = data
    @safePath {filePath: path}, (error, safePath) =>    
      data.newPath = safePath    
      @run 
        withArgs  : 
          command : "cp -R #{@escapeFilePath path} #{@escapeFilePath safePath}"
      , (error, response)->
        if error then warn error
        else
          file = CommandParser.createFile safePath, 'fileData.type'
        callback error, file
      
    
  rename: ({fileData, newName}, callback) ->
    # [subPath..., oldName] = path.split('/')
    [subPath..., oldName] = fileData.path.split('/')
    subPath = subPath.join '/'
    oldPath = subPath + '/' + fileData.name
    newPath = subPath + '/' + newName
    if oldPath is newPath
      return warn 'rename got same file names, ignoring operation'
      
    fileData.path = newPath
    fileData.name = newName
    oldPath = @escapeFilePath oldPath
    newPath = @escapeFilePath newPath
    command = "mv #{oldPath} #{newPath}"
    @run 
      withArgs  : 
        command : command
    , callback
    
  move: ({items, moveTo}, callback) ->
    @_copyOrMove {items, to: moveTo, type: 'move'}, callback
      
  copy: ({items, copyTo}, callback) ->
    @_copyOrMove {items, to: copyTo, type: 'copy'}, callback
      
  _copyOrMove: ({items, to, type}, callback) ->
    stack     = []
    newFiles  = []
    for item in items
      do (item) =>
        stack.push (callback) =>
          if type is 'copy'
            command = "cp -R #{@escapeFilePath(item.path)} #{@escapeFilePath(to.path)}"
          else
            command = "mv #{@escapeFilePath(item.path)} #{@escapeFilePath(to.path)}"
          @run 
            withArgs  : 
              command : command
          , (error, response)->
            newFiles.push CommandParser.createFile (to.path + '/' + item.name), item.type
            callback error, response
    
    async.parallel stack, (error, result) ->
      callback error, newFiles
    
  remove: ({fileData, path}, callback) ->
    path = @escapeFilePath path
    @run 
      withArgs  : 
        command : "rm -r #{path}"
    , callback
    
  makePublic: (files, callback) ->
    # log files
    file = files[0]
    # paths = for file in files
    #   file.path
    @run 
      toDo          : "prepareFileForDownload"
      withArgs      : 
        pathToFile  : file.path
        command     : "touch #{@escapeFilePath file.path}"
    , callback

  extract: (data, callback) ->
    {path} = data
    (pathInfo = path.split('/')).pop()
    withArgs =
      pathToArchive: path
      dest: pathInfo.join('/')
      
    @run {withArgs}, (error, result) =>
      unless error
        folder = CommandParser.createFile (result), 'folder'
        callback null, folder
      else
        callback error
        
  __shortestPath: (paths) ->
    intersection = (path1, path2) ->
      pathInfo1 = path1.split '/'
      pathInfo2 = path2.split '/'

      result = []
      for slug, index in pathInfo1
        if pathInfo2[index]?
          if slug is pathInfo2[index]
            result.push slug
          else
            break
        else
          break

      result

    temp = []

    if paths.length is 1
      paths.push '/Users/' + (KD.whoami().profile?.nickname or '')

    for path, index in paths
      if paths[index + 1]
        temp.push intersection(path, paths[index + 1]).join '/'

    temp.sort (a, b) -> if a.length < b.length then -1 else 1
    shortestPath = temp.shift() + '/'
    
  compress: (data, callback) ->
    {datas, paths}  = data
    fileName = (containerFolder = paths[0].split('/')).pop()
    # containerFolder = containerFolder.join '/'
    
    shortestPathToFolder = @__shortestPath paths
    if paths.length is 1
      archiveName = shortestPathToFolder +  fileName + '.zip'
    else
      archiveName = shortestPathToFolder + 'NewArchive.zip'
    
    @safePath {filePath:archiveName}, (error, safePath) =>
      data.newPath  = safePath
      
      escapedPaths  = ""
      for path in paths
        if path.indexOf(shortestPathToFolder) is 0
          escapedPaths += @escapeFilePath path.substr(shortestPathToFolder.length)
        else
          escapedPaths += @escapeFilePath path
          
      fullSafePath = safePath
      if safePath.indexOf(shortestPathToFolder) is 0
        safePath = safePath.substr(shortestPathToFolder.length)
      
      @run 
        withArgs  :
          command : "cd #{@escapeFilePath shortestPathToFolder};zip #{@escapeFilePath safePath} #{escapedPaths}"
      , (error, response) ->
        if error then warn error
        else
          file = CommandParser.createFile fullSafePath, 'file'
        callback error, file
    
  #FIXME::!!!! These are un-secure- sah 12/27/11
  #i don't know why saleem says that, worth to check Sinan 4/25/12
  safePath: (pathObj, callback) ->
    @run
      toDo      : "fetchSafeFileName"
      withArgs  : pathObj
    , callback
    
  chmod: (params, callback) ->
    {permissions, recursive, fileData, path} = params
    fileData.mode = permissions

    @run 
      withArgs  : 
        command : "chmod #{if recursive then '-R' else ''} #{permissions} #{@escapeFilePath path}"
    , callback
  
  stat: (params, callback)->

    @run
      withArgs  :
        command : "stat #{@escapeFilePath params.path}"
    , (error, response) ->
      if error then warn error
      else
        CommandParser.parseStat params.fileData, response
        callback.apply null, arguments
        params.callback.apply null, arguments

  saveToDefaultCodeSnippetFolder: (title, contents, callback)->
    # This custom method is used because FS, command, environment are all a mess and devrim is currently working on refactoring them - 3/15/12 sah
    account = KD.whoami()
    dirPath = "#{account.getRootPath()}/CodeSnippets"
    @run 
      withArgs  :
        command : "mkdir -p #{dirPath}"
    , (error, response)=>
      if error then callback error
      else
        @safePath filePath : "#{dirPath}/#{title}", (error, safePath)->
          if error then callback error
          else
            @saveFile
              newFile    : 
                path     : safePath
                contents : contents
            , (error, url)=>
              if error 
                callback error 
              else 
                command.run 
                  withArgs  :
                    command : "curl -L #{url}>#{safePath}"
                , (error, response)->
                  callback error, safePath

    
  isValidFileName: (name) ->
    CommandParser.isValidFileName name
    
  escapeFilePath: (name) ->
    CommandParser.escapeFilePath name