class FSHelper

  parseWatcherFile = ({ vmName, parentPath, file, user, treeController, osKite })->
  @createFileInstance = (options)->

    if typeof options is 'string'
      options = path: options
    else if not options?.path?
      return warn "pass a path and type to create a file instance"

    unless options.machine?
      warn "No machine instance passed, creating dummy file instance"
      options.machine = new DummyMachine

    options.type       ?= "file"
    options.name       ?= @getFileNameFromPath options.path
    options.parentPath ?= @getParentPath       options.path

    if @registry[options.path]
      instance = @registry[options.path]
      @updateInstance options
    else
      constructor = switch options.type
        when "mount"      then FSMount
        when "folder"     then FSFolder
        when "symLink"    then FSFolder
        when "machine"    then FSMachine
        when "brokenLink" then FSBrokenLink
        else FSFile

      instance = new constructor options
      @register instance

    return instance

    {name, size, mode} = file
    type      = if file.isBroken then 'brokenLink' else \
                if file.isDir then 'folder' else 'file'
    path      = if parentPath is "[#{vmName}]/" then "[#{vmName}]/#{name}" else \
                "#{parentPath}/#{name}"
    group     = user
    createdAt = file.time
    return { size, user, group, createdAt, mode, type, \
             parentPath, path, name, vmName:vmName, treeController, osKite }

  @handleStdErr = ->
    (result) ->
      { stdout, stderr, exitStatus } = result
      throw new Error "std error: #{ stderr }"  if exitStatus > 0
      return result

  @parseWatcher = ({ vmName, parentPath, files, treeController, osKite })->
    data = []
    return data unless files
    files = [files] unless Array.isArray files

    { partition, sortFiles } = KD.utils

    sortedFiles = partition(files.sort(sortFiles), (file) -> file.isDir)
      .reduce (acc, next) -> acc.concat next

    nickname = KD.nick()
    for file in sortedFiles
      data.push FSHelper.createFile \
        parseWatcherFile {
          vmName
          parentPath
          file
          nickname
          treeController
        }

    return data

  @folderOnChange = ({ vmName, path, change, treeController })->
    return  unless treeController
    [ file ] = @parseWatcher {
      vmName
      parentPath  : path
      files       : change.file
      treeController
    }
    switch change.event
      when "added"
        treeController.addNode file
      when "removed"
        for own npath, node of treeController.nodes
          if npath is file.path
            treeController.removeNodeView node
            break

  @getFileExtension: (path) ->
    fileName = path or ''
    [name, extension...]  = fileName.split '.'
    extension = if extension.length is 0 then '' else extension.last
    return extension

  @plainPath:(path)-> path.replace /^\[.*\]/, ''
  @getVMNameFromPath:(path)-> (/^\[([^\]]+)\]/g.exec path)?[1]

  @minimizePath: (path)-> @plainPath(path).replace ///^\/home\/#{KD.nick()}///, '~'

  @exists = (path, vmName, callback=noop)->
    @getInfo path, vmName, (err, res)->
      callback err, res?

  @getInfo = (path, vmName, callback=noop)->
    KD.getSingleton('vmController').run
      method   : "fs.getInfo"
      vmName   : vmName
      withArgs : {path, vmName}
    , callback

  @glob = (pattern, vmName, callback)->
    [vmName, callback] = [callback, vmName]  if typeof vmName is "function"
    KD.getSingleton('vmController').run
      method   : "fs.glob"
      vmName   : vmName
      withArgs : {pattern, vmName}
    , callback

  @uniquePath = (path, vmName, callback=noop)->
    KD.getSingleton('vmController').run
      method   : "fs.uniquePath"
      vmName   : vmName
      withArgs : {path, vmName}
    , callback

  @registry = {}

  @resetRegistry:-> @registry = {}

  @register = (file)->
    @setFileListeners file
    @registry[file.path] = file

  @unregister = (path)->
    delete @registry[path]

  @unregisterVmFiles = (vmName)->
    for own path, file of @registry  when (path.indexOf "[#{vmName}]") is 0
      @unregister path

  @updateInstance = (fileData)->
    for own prop, value of fileData
      @registry[fileData.path][prop] = value

  @setFileListeners = (file)->
    file.on "fs.job.finished", =>

  @getFileNameFromPath = getFileName = (path)->
    return path.split('/').pop()

  @trimExtension = (path)->
    name = getFileName path
    return name.split('.').shift()

  @getParentPath = (path)->
    path = path.substr(0, path.length-1) if path.substr(-1) is "/"
    parentPath = path.split('/')
    parentPath.pop()
    return parentPath.join('/')

  @createRecursiveFolder = ({ path, vmName }, callback = noop) ->
    return warn "Pass a path to create folders recursively"  unless path

    KD.getSingleton("vmController").run {
      method      : "fs.createDirectory"
      withArgs    : {
        recursive : yes
        path
      }
      vmName
    }, callback

  @isValidFileName = (name) ->
    return /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test name

  @isEscapedPath = (path) ->
    return /^\s\"/.test path

  @escapeFilePath = (name) ->
    return FSHelper.plainPath name.replace(/\'/g, '\\\'').replace(/\"/g, '\\"').replace(/\ /g, '\\ ')

  @unescapeFilePath = (name) ->
    return name.replace(/^(\s\")/g,'').replace(/(\"\s)$/g, '').replace(/\\\'/g,"'").replace(/\\"/g,'"')

  @isPublicPath = (path)->
    /^\/home\/.*\/Web\//.test FSHelper.plainPath path

  @convertToRelative = (path)->
    path.replace(/^\//, "").replace /(.+?)\/?$/, "$1/"

  @isUnwanted = (path, isFile=no)->

    dummyFilePatterns = /\.DS_Store|Thumbs.db/
    dummyFolderPatterns = /\.git|__MACOSX/
    if isFile
    then dummyFilePatterns.test path
    else dummyFolderPatterns.test path

  @s3 =
    get    : (name)->
      "#{KD.config.uploadsUri}/#{KD.whoami().getId()}/#{name}"

    getGroupRelated : (group, name)->
      "#{KD.config.uploadsUriForGroup}/#{group}/#{name}"

    upload : (name, content, bucket, path, callback)->
      args = {name, bucket, path, content}

      KD.getSingleton('vmController').run
        method    : 's3.store'
        withArgs  : args
      , (err, res)->
        return callback err if err
        filePath = if bucket is "groups" then FSHelper.s3.getGroupRelated path, name else FSHelper.s3.get name
        callback null, filePath

    remove : (name, callback)->
      vmController = KD.getSingleton 'vmController'
      vmController.run
        method    : 's3.delete'
        withArgs  : {name}
      , callback

  @getPathHierarchy = (fullPath)->
    {path, vmName} = KD.getPathInfo fullPath
    path = path.replace /^~/, "/home/#{KD.nick()}"
    nodes = path.split("/").filter (node)-> return !!node
    queue = for node in nodes
      subPath = nodes.join "/"
      nodes.pop()
      "[#{vmName}]/#{subPath}"
    queue.push "[#{vmName}]/"
    return queue

  @chunkify = (data, chunkSize)->
    chunks = []
    while data
      if data.length < chunkSize
        chunks.push data
        break
      else
        chunks.push data.substr 0, chunkSize
        # shrink
        data = data.substr chunkSize
    return chunks

  @getFullPath = (file)->
    plainPath = @plainPath file.path
    return "[#{file.vmName}]#{plainPath}"
  # Extension helpers
  #

  @getFileType = (extension)->

    fileType = null

    _extension_sets =
      code    : [
        "php", "pl", "py", "jsp", "asp", "htm","html", "phtml","shtml"
        "sh", "cgi", "htaccess","fcgi","wsgi","mvc","xml","sql","rhtml"
        "js","json","coffee", "css","styl","sass", "erb"
      ]
      text    : [
        "txt", "doc", "rtf", "csv", "docx", "pdf"
      ]
      archive : [
        "zip","gz","bz2","tar","7zip","rar","gzip","bzip2","arj","cab"
        "chm","cpio","deb","dmg","hfs","iso","lzh","lzma","msi","nsis"
        "rpm","udf","wim","xar","z","jar","ace","7z","uue"
      ]
      image   : [
        "png","gif","jpg","jpeg","bmp","svg","psd","qt","qtif","qif"
        "qti","tif","tiff","aif","aiff"
      ]
      video   : [
        "avi","mp4","h264","mov","mpg","ra","ram","mpg","mpeg","m4a"
        "3gp","wmv","flv","swf","wma","rm","rpm","rv","webm"
      ]
      sound   : ["aac","au","gsm","mid","midi","snd","wav","3g2","mp3","asx","asf"]
      app     : ["kdapp"]


    for own type,set of _extension_sets
      for ext in set when extension is ext
        fileType = type
        break
      break if fileType

    return fileType or 'unknown'


KD.classes.FSHelper = FSHelper
