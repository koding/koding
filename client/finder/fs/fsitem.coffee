class FSItem extends KDObject

  ###
  CLASS CONTEXT
  ###

  { escapeFilePath } = FSHelper

  @create:({ path, type, osKite, treeController }, callback)->

    osKite.vmStart()

    .then =>
      osKite.fsEnsureNonexistentPath({ path })
      .then (actualPath) =>

        plainPath = FSHelper.plainPath actualPath

        method = 
          if type is "folder"
          then "fsCreateDirectory"
          else "fsWriteFile"

        options =
          path            : plainPath
          content         : ''
          donotoverwrite  : yes

        osKite[method](options)
        .then ->
          file = FSHelper.createFile {
            path: plainPath
            type
            osKite
          }

          callback null, file

    .catch (err) ->
      warn err
      callback err

  @copyOrMove:(sourceItem, targetItem, commandPrefix, callback)->
    sourceItem.emit "fs.job.started"
    
    { osKite } = sourceItem

    targetPath = FSHelper.plainPath "#{targetItem.path}/#{sourceItem.name}"
    
    osKite.vmStart()

    .then ->
      osKite.fsEnsureNonexistentPath(path: targetPath)
      .then (actualPath) ->
        command = "#{ commandPrefix } #{ escapeFilePath sourceItem.path } #{ escapeFilePath actualPath }"

        osKite.exec(command)
        .then ->

          file = FSHelper.createFile {
            path        : actualPath
            parentPath  : targetItem.path
            name        : sourceItem.name
            type        : sourceItem.type
            osKite
          }

          callback null, file

    .catch (err) ->
      warn err
      callback err

    .then ->
      sourceItem.emit "fs.job.finished"

  @copy: (sourceItem, targetItem, callback) ->
    @copyOrMove sourceItem, targetItem, 'cp -R', callback

  @move:(sourceItem, targetItem, callback)->
    @copyOrMove sourceItem, targetItem, 'mv', callback

  @compress:(file, type, callback)->

    file.emit "fs.job.started"

    { osKite }  = file

    path = FSHelper.plainPath "#{file.path}.#{type}"

    osKite.vmStart()

    .then ->
      osKite.fsEnsureNonexistentPath({ path })
      .then (actualPath) ->

        command =
          if type is "tar.gz"
            "tar -pczf #{escapeFilePath actualPath} #{escapeFilePath file.path}"
          else
            "zip -r #{escapeFilePath actualPath} #{escapeFilePath file.path}"

        osKite.exec(command)
        .then (response) ->
          callback null, response

    .catch (err) ->
      warn err
      callback err

    .then ->
      file.emit "fs.job.finished"

  @extract: (file, callback = (->)) ->
    file.emit "fs.job.started"

    { osKite } = file

    tarPattern = /\.tar\.gz$/
    zipPattern = /\.zip$/

    path = FSHelper.plainPath file.path
    
    [isTarGz, extractFolder] =
      if tarPattern.test file.name
        [yes, path.replace tarPattern, '']
      else if zipPattern.test file.name
        [no, path.replace zipPattern, '']

    osKite.vmStart()

    .then ->
      osKite.fsEnsureNonexistentPath(path: "#{ extractFolder }")
      .then (actualPath) ->

        command =
          if isTarGz
            "cd #{escapeFilePath file.parentPath};mkdir -p #{escapeFilePath actualPath};tar -zxf #{escapeFilePath file.name} -C #{escapeFilePath actualPath}"
          else
            "cd #{escapeFilePath file.parentPath};unzip -o #{escapeFilePath file.name} -d #{escapeFilePath actualPath}"

        console.log command

        osKite.exec(command)
        .then ->

          file = FSHelper.createFile {
            path            : actualPath
            parentPath      : file.parentPath
            type            : 'folder'
            osKite
          }

          callback null, file

    .catch (err) ->
      warn err
      callback err

    .then ->
      file.emit "fs.job.finished"

  @getFileExtension: (path) ->
    fileName = path or ''
    [name, extension...]  = fileName.split '.'
    extension = if extension.length is 0 then '' else extension.last

  @getFileType: (extension)->

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

  @isHidden: (name)-> return /^\./.test name

  ###
  INSTANCE METHODS
  ###

  constructor:(options, data)->

    @[key] = value for own key, value of options

    super

    @vmController   = KD.getSingleton('vmController')

  getExtension:-> FSItem.getFileExtension @name

  getPath: -> FSHelper.plainPath @path

  isHidden:-> FSItem.isHidden @name

  exists:(callback=noop)->
    @osKite.vmStart()

    .fsExists(path: @getPath())

    .then (result) ->
      callback null, result

    .catch (err) ->
      warn err
      callback err

  stat:(callback=noop)->
    @osKite.vmStart()

    .then =>
      @osKite.fsGetInfo path: @getPath()

    .then (result) ->
      callback null, result
    
    .catch (err) ->
      warn err
      callback err

  remove:(callback, recursive=no)->
    @emit "fs.delete.started"

    @osKite.vmStart()

    .then =>
      @osKite.fsRemove(path: @getPath())

    .then (result) ->
      callback null, result

    .catch (err) ->
      warn err
      callback err

    .then =>
      @emit "fs.delete.finished"

  rename:(newName, callback)->

    newPath = FSHelper.plainPath "#{@parentPath}/#{newName}"

    @emit "fs.job.started"

    @osKite.vmStart()

    .then =>
      @osKite.fsEnsureNonexistentPath(path: @getPath())

    .then (response) =>
      @osKite.fsRename(
        oldpath: @getPath()
        newpath: newPath
      )

    .then ->
      callback null

    .catch (err) ->
      warn err
      callback err

    .then =>
      @emit "fs.job.finished"

  chmod:(options, callback)->

    { recursive, permissions: mode } = options

    @mode = mode

    return callback? new Error "no permissions passed"  unless mode?

    @emit "fs.job.started"

    @osKite.vmStart()

    .then =>
      @osKite.fsSetPermissions({
        path: @getPath()
        recursive
        mode
      })

    .then (response) =>
      callback null, response

    .catch (err) ->
      warn err
      callback err

    .then =>
      @emit "fs.job.started"
