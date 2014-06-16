class FSItem extends KDObject

  ###
  CLASS CONTEXT
  ###

  { escapeFilePath, handleStdErr } = FSHelper

  @create:({ path, type, vmName, treeController }, callback)->

    kite = FSItem.getKite {vmName}

    kite.vmOn().then ->

      plainPath = FSHelper.plainPath path

      method =
        if type is "folder"
        then "fsCreateDirectory"
        else "fsWriteFile"

      options =
        path            : plainPath
        content         : ''
        donotoverwrite  : yes

      kite.fsUniquePath(path: plainPath).then (actualPath) ->

        options.path = actualPath

        kite[method](options).then (stat) ->

          FSHelper.createFile {
            path: actualPath
            type
            vmName
          }

      .nodeify(callback)

  @copyOrMove:(sourceItem, targetItem, commandPrefix, callback)->
    sourceItem.emit "fs.job.started"

    kite = sourceItem.getKite()

    targetPath = FSHelper.plainPath "#{targetItem.path}/#{sourceItem.name}"

    file = null

    kite.vmOn().then ->

      kite.fsUniquePath(path: targetPath).then (actualPath) ->

        command = "#{ commandPrefix } #{ escapeFilePath sourceItem.path } #{ escapeFilePath actualPath }"

        kite.exec({command})

        .then(handleStdErr())

        .then ->
          file = FSHelper.createFile {
            path        : actualPath
            parentPath  : targetItem.path
            name        : sourceItem.name
            type        : sourceItem.type
            vmName      : sourceItem.vmName
          }

          return file

    .nodeify(callback)

    .finally ->
      sourceItem.emit "fs.job.finished"

      return file

  @copy: (sourceItem, targetItem, callback) ->
    @copyOrMove sourceItem, targetItem, 'cp -R', callback

  @move:(sourceItem, targetItem, callback)->

    newName = FSHelper.plainPath "#{ targetItem.path }/#{ sourceItem.name }"
    sourceItem.rename path: newName, callback

  @compress:(file, type, callback)->

    file.emit "fs.job.started"

    kite = file.getKite()

    path = FSHelper.plainPath "#{file.path}.#{type}"

    kite.vmOn().then ->

      kite.fsUniquePath { path }

    .then (actualPath) ->

      command =
        if type is "tar.gz"
          "tar -pczf #{escapeFilePath actualPath} #{escapeFilePath file.path}"
        else
          "zip -r #{escapeFilePath actualPath} #{escapeFilePath file.path}"

      kite.exec {command}

    .then(handleStdErr())

    .nodeify(callback)

    .finally ->
      file.emit "fs.job.finished"

  @extract: (file, callback = (->)) ->
    file.emit "fs.job.started"

    kite = file.getKite()

    tarPattern = /\.tar\.gz$/
    zipPattern = /\.zip$/

    path = FSHelper.plainPath file.path

    [isTarGz, extractFolder] = switch

      when tarPattern .test file.name
        [yes, path.replace tarPattern, '']

      when zipPattern .test file.name
        [no, path.replace zipPattern, '']

    kite.vmOn()

    .then ->
      kite.fsUniquePath(path: "#{ extractFolder }")

    .then (actualPath) ->

      command =
        if isTarGz
          "cd #{escapeFilePath file.parentPath};mkdir -p #{escapeFilePath actualPath};tar -zxf #{escapeFilePath file.name} -C #{escapeFilePath actualPath}"
        else
          "cd #{escapeFilePath file.parentPath};unzip -o #{escapeFilePath file.name} -d #{escapeFilePath actualPath}"

      kite.exec({command})

    .then(handleStdErr())

    .then ->

      file = FSHelper.createFile {
        path            : actualPath
        parentPath      : file.parentPath
        type            : 'folder'
        vmName          : file.vmName
      }

      return file

    .nodeify(callback)

    .finally ->
      file.emit "fs.job.finished"

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
    kite = @getKite()

    kite.vmOn().then =>

      kite.fsExists(path: @getPath())

    .nodeify(callback)

  stat:(callback=noop)->
    kite = @getKite()

    kite.vmOn().then =>

      kite.fsGetInfo path: @getPath()

    .nodeify(callback)

  remove:(callback, recursive=no)->
    @emit "fs.delete.started"

    kite = @getKite()

    kite.vmOn().then =>

      kite.fsRemove { path: @getPath(), recursive }

    .nodeify(callback)

    .then =>
      @emit "fs.delete.finished"

  rename: ({ name: newName, path: newPath }, callback)->

    newPath ?= FSHelper.plainPath "#{@parentPath}/#{newName}"

    @emit "fs.job.started"

    kite = @getKite()

    kite.vmOn()

    .then =>
      kite.fsRename(
        oldpath: @getPath()
        newpath: newPath
      )

    .nodeify(callback)

    .then =>
      @emit "fs.job.finished"

  chmod:(options, callback)->

    { recursive, permissions: mode } = options

    @mode = mode

    return callback? new Error "no permissions passed"  unless mode?

    @emit "fs.job.started"

    kite = @getKite()

    kite.vmOn().then =>

      kite.fsSetPermissions {
        path: @getPath()
        recursive
        mode
      }

    .nodeify(callback)

    .then =>
      @emit "fs.job.started"

  getKite: ->
    if @options.dummy
      return null

    FSItem.getKite { @vm, @vmName }

  @getKite = ({vm, vmName})->
    if KD.useNewKites
      kontrol = KD.getSingleton 'kontrol'
      kontrol.getKite \
        if vm?
          name              : 'oskite'
          correlationName   : vm.hostnameAlias
          region            : vm.region
        else
          name              : 'oskite'
          correlationName   : vmName
    else
      KD.getSingleton('vmController').getKiteByVmName vmName
