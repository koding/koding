class FSItem extends KDObject

  ###
  CLASS CONTEXT
  ###

  escapeFilePath = FSHelper.escapeFilePath

  @create:(path, type, callback)->

    FSItem.getSafePath path, (err, response)->
      if err
        callback? err, response
        warn err
      else
        KD.getSingleton('kiteController').run
          withArgs  :
            command : "#{if type is 'file' then 'touch' else 'mkdir -p'} #{escapeFilePath response}"
        , (err, res)->
          if err then warn err
          else
            file = FSHelper.createFileFromPath response, type
          callback? err, file

  @getSafePath:(path, callback) ->

    KD.getSingleton('kiteController').run
      method      : "fetchSafeFileName"
      withArgs    :
        filePath  : path
    , callback

  @doesExist:(path, callback) ->
    KD.getSingleton('kiteController').run "test -d #{escapeFilePath path}", (err, stderr, stdout)=>
      if err?.code > 0
        callback null, no
      else
        callback err, yes

  @copy:(sourceItem, targetItem, callback)->

    sourceItem.emit "fs.copy.started"
    FSItem.getSafePath "#{targetItem.path}/#{sourceItem.name}", (err, response)->
      if err
        warn err
        callback? err, response
      else
        KD.getSingleton('kiteController').run
          withArgs  :
            command : "cp -R #{escapeFilePath(sourceItem.path)} #{escapeFilePath(response)}"
        , (err, res)->
          sourceItem.emit "fs.copy.finished"
          if err then warn err
          else
            file = FSHelper.createFileFromPath "#{targetItem.path}/#{sourceItem.name}", sourceItem.type
          callback? err, file

  @move:(sourceItem, targetItem, callback)->

    sourceItem.emit "fs.move.started"
    FSItem.getSafePath "#{targetItem.path}/#{sourceItem.name}", (err, response)->
      if err
        warn err
        callback? err, response
      else
        KD.getSingleton('kiteController').run
          withArgs  :
            command : "mv #{escapeFilePath(sourceItem.path)} #{escapeFilePath(response)}"
        , (err, res)->
          sourceItem.emit "fs.move.finished"
          if err then warn err
          else
            file = FSHelper.createFileFromPath "#{targetItem.path}/#{sourceItem.name}", sourceItem.type
          callback? err, file

  @compress:(file, type, callback)->

    file.emit "fs.compress.started"
    FSItem.getSafePath "#{file.path}.#{type}", (err, response)->
      if err
        warn err
        callback? err, response
      else
        command = switch type
          when "tar.gz" then "tar -pczf #{escapeFilePath response} #{escapeFilePath file.path}"
          else "zip -r #{escapeFilePath response} #{escapeFilePath file.path}"
        KD.getSingleton('kiteController').run
          withArgs  : {command}
        , (err, res)->
          file.emit "fs.compress.finished"
          if err then warn err
          callback? err, res

  @extract:(file, callback)->

    file.emit "fs.extract.started"
    FSItem.create file.path, "folder", (err, folder)=>
      if err then warn err
      else
        command = if /\.tar\.gz$/.test file.name
          "cd #{escapeFilePath file.parentPath};tar -zxf #{escapeFilePath file.name} -C #{folder.path}"
        else if /\.zip$/.test file.name
          "cd #{escapeFilePath file.parentPath};unzip #{escapeFilePath file.name} -d #{folder.path}"
      KD.getSingleton('kiteController').run
        withArgs  : {command}
      , (err, res)->
        file.emit "fs.extract.finished"
        if err then warn err
        callback? err, folder

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
        "js","json","coffee"
        "css","styl","sass"
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
        "3gp","wmv","flv","swf","wma","rm","rpm","rv"
      ]
      sound   : ["aac","au","gsm","mid","midi","snd","wav","3g2","mp3","asx","asf"]
      app     : ["kdapp"]


    for own type,set of _extension_sets
      for ext in set when extension is ext
        fileType = type
        break
      break if fileType

    return fileType or 'unknown'


  ###
  INSTANCE METHODS
  ###

  constructor:(options, data)->

    @[key] = value for own key, value of options

    super

    @kiteController = @getSingleton('kiteController')

  getExtension:-> FSItem.getFileExtension @name

  remove:(callback)->

    @emit "fs.delete.started"
    @kiteController.run
      withArgs  :
        command : "rm -r #{escapeFilePath @path}"
    , (err, response)=>
      callback err, response
      if err then warn err
      else
        @emit "fs.delete.finished"
        @destroy()

  rename:(newName, callback)->

    newPath = "#{@parentPath}/#{newName}"

    @emit "fs.rename.started"
    FSItem.getSafePath newPath, (err, response)=>
      if err
        warn err
        callback? err, response
      else
        KD.getSingleton('kiteController').run
          withArgs  :
            command : "mv #{escapeFilePath(@path)} #{escapeFilePath(response)}"
        , (err, res)=>
          if err then warn err
          else
            @path = newPath
            @name = newName
          callback? err, @
          @emit "fs.rename.finished"

  chmod:(options, callback)->

    {recursive, permissions} = options

    return callback? "no permissions passed" unless permissions
    @emit "fs.chmod.started"
    @kiteController.run
      withArgs  :
        command : "chmod #{if recursive then '-R' else ''} #{permissions} #{escapeFilePath @path}"
    , (err, res)=>
      @emit "fs.chmod.finished", recursive
      if err then warn err
      else
        @mode = permissions
      callback? err,res
