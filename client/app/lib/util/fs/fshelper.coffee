nick = require '../nick'
whoami = require '../whoami'
DummyMachine = require '../../providers/dummymachine'
kd = require 'kd'
sortFiles = require '../sortFiles'
globals = require 'globals'

module.exports = class FSHelper

  @createFileInstance = (options)->

    if typeof options is 'string'
      options = path: options
    else if not options?.path?
      return kd.warn "pass a path and type to create a file instance"

    if options.machine
      unless options.path.indexOf('localfile:/') is 0
        # make sure that we machine and it's uid in path
        options.path = "[#{options.machine.uid}]#{@plainPath options.path}"
    else
      kd.warn "No machine instance passed, creating dummy file instance"
      options.machine = new DummyMachine

    options.type       ?= "file"
    options.name       ?= @getFileNameFromPath options.path
    options.parentPath ?= @getParentPath       options.path

    if @registry[options.path]
      instance = @registry[options.path]
      @updateInstance options
    else
      constructor = switch options.type
        when "mount"      then require './fsmount'
        when "folder"     then require './fsfolder'
        when "symLink"    then require './fsfolder'
        when "machine"    then require './fsmachine'
        when "brokenLink" then require './fsbrokenlink'
        else require './fsfile'

      instance = new constructor options
      @register instance

    return instance

  parseWatcherFile = ({ machine, parentPath, file, user, treeController })->

    { uid } = machine
    {name, size, mode} = file

    type      = if file.isBroken then 'brokenLink' else \
                if file.isDir then 'folder' else 'file'
    path      = if parentPath is "[#{uid}]/" then "[#{uid}]/#{name}" else \
                "#{parentPath}/#{name}"
    group     = user
    createdAt = file.time

    return { size, user, group, createdAt, mode, type, \
             parentPath, path, name, machine, treeController }

  @parseWatcher = ({ machine, parentPath, files, treeController })->

    data = []
    return data unless files
    files = [files] unless Array.isArray files

    sortedFiles = kd.utils.partition(files.sort(sortFiles), (file) -> file.isDir)
      .reduce (acc, next) -> acc.concat next

    for file in sortedFiles
      data.push FSHelper.createFileInstance \
        parseWatcherFile { file, machine, parentPath, treeController }

    return data


  @folderOnChange = ({ machine, path, change, treeController })->
    return  unless treeController
    [ file ] = @parseWatcher {
      parentPath : path
      files      : change.file
      treeController, machine
    }
    switch change.event
      when "added"
        treeController.addNode file
      when "removed"
        node = treeController.nodes["#{path}/#{change.file.name}"]
        treeController.removeNodeView node  if node

  @getFileExtension: (path) ->
    fileName = path or ''
    [name, extension...]  = fileName.split '.'
    extension = if extension.length is 0 then '' else extension.last
    return extension

  @plainPath:(path)-> path.replace /^\[.*?\]/, ''
  @getVMNameFromPath:(path)-> (/^\[([^\]]+)\]/g.exec path)?[1]

  @getUidFromPath:(path)-> (/^\[([^\]]+)\]/g.exec path)?[1]

  @handleStdErr = ->
    (result) ->
      { stdout, stderr, exitStatus } = result
      throw new Error "std error: #{ stderr }"  if exitStatus > 0
      return result

  @minimizePath: (path)-> @plainPath(path).replace ///^\/home\/#{nick()}///, '~'

  # @exists = (path, vmName, callback=noop)->
  #   @getInfo path, vmName, (err, res)->
  #     callback err, res?

  # @getInfo = (path, vmName, callback=noop)->
  #   KD.getSingleton('vmController').run
  #     method   : "fs.getInfo"
  #     vmName   : vmName
  #     withArgs : {path, vmName}
  #   , callback

  # @glob = (pattern, vmName, callback)->
  #   [vmName, callback] = [callback, vmName]  if typeof vmName is "function"
  #   KD.getSingleton('vmController').run
  #     method   : "fs.glob"
  #     vmName   : vmName
  #     withArgs : {pattern, vmName}
  #   , callback

  @registry = {}

  @resetRegistry:-> @registry = {}

  @register = (file)->
    @setFileListeners file
    @registry[file.path] = file

  @unregister = (path)->
    delete @registry[path]

  @unregisterMachineFiles = (uid)->
    for own path, file of @registry  when (path.indexOf "[#{uid}]") is 0
      @unregister path

  @updateInstance = (fileData)->
    for own prop, value of fileData
      @registry[fileData.path][prop] = value

  @setFileListeners = (file)->
    file.on "fs.job.finished", =>

  @getFileNameFromPath = (path)->
    return path.split('/').pop()

  @trimExtension = (path)->
    name = FSHelper.getFileName path
    return name.split('.').shift()

  @getParentPath = (path)->

    uid = @getUidFromPath path
    if uid? then path = @plainPath path

    path   = path.replace /\/$/, ''
    parent = path.split '/'; parent.pop(); parent = parent.join '/'
    parent = "/"  if parent is ""
    parent = "[#{uid}]#{parent}"  if uid

    return parent

  # @createRecursiveFolder = ({ path, vmName }, callback = noop) ->
  #   return warn "Pass a path to create folders recursively"  unless path

  #   KD.getSingleton("vmController").run {
  #     method      : "fs.createDirectory"
  #     withArgs    : {
  #       recursive : yes
  #       path
  #     }
  #     vmName
  #   }, callback

  @escapeFilePath = (name) ->
    return FSHelper.plainPath name.replace(/\'/g, '\\\'').replace(/\"/g, '\\"').replace(/\ /g, '\\ ')

  @unescapeFilePath = (name) ->
    return name.replace(/^(\s\")/g,'').replace(/(\"\s)$/g, '').replace(/\\\'/g,"'").replace(/\\"/g,'"')

  @convertToRelative = (path)->
    path.replace(/^\//, "").replace /(.+?)\/?$/, "$1/"

  @isValidFileName = (name) ->
    return /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test name

  @isEscapedPath = (path) ->
    return /^\s\"/.test path

  @isPublicPath = (path)->
    /^\/home\/.*\/Web\//.test FSHelper.plainPath path

  @isHidden = (name)-> /^\./.test name

  @isUnwanted = (path, isFile=no)->

    dummyFilePatterns = /\.DS_Store|Thumbs.db/
    dummyFolderPatterns = /\.git|__MACOSX/
    if isFile
    then dummyFilePatterns.test path
    else dummyFolderPatterns.test path

  @s3 =
    get    : (name)->
      "#{globals.config.uploadsUri}/#{whoami().getId()}/#{name}"

    getGroupRelated : (group, name)->
      "#{globals.config.uploadsUriForGroup}/#{group}/#{name}"

    upload : (name, content, bucket, path, callback)->
      args = {name, bucket, path, content}

      kd.getSingleton('vmController').run
        method    : 's3.store'
        withArgs  : args
      , (err, res)->
        return callback err if err
        filePath = if bucket is "groups" then FSHelper.s3.getGroupRelated path, name else FSHelper.s3.get name
        callback null, filePath

    remove : (name, callback)->
      vmController = kd.getSingleton 'vmController'
      vmController.run
        method    : 's3.delete'
        withArgs  : {name}
      , callback

  @getPathHierarchy = (fullPath)->
    # had to require getPathInfo over here to prevent circular dep issues
    {path, machineUid} = require('../getPathInfo') fullPath
    path = path.replace /^~/, "/home/#{nick()}"
    nodes = path.split("/").filter (node)-> return !!node
    queue = for node in nodes
      subPath = nodes.join "/"
      nodes.pop()
      "[#{machineUid}]/#{subPath}"
    queue.push "[#{machineUid}]/"
    return queue

  @getFullPath = (file)->
    plainPath = @plainPath file.path
    return "[#{file.machine.uid}]#{plainPath}"

  # FS Chunk helpers
  #

  @createChunkQueue = (data = "", skip=0, chunkSize=1024*1024)->

    chunks     = FSHelper.chunkify data, chunkSize
    queue      = []

    for chunk, index in chunks
      isSkip = skip > index
      queue.push
        content : unless isSkip then btoa chunk
        skip    : isSkip
        append  : queue.length > 0 # first chunk is not an append

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
