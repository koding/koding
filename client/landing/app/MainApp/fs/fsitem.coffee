class FSItem extends KDObject

  ###
  CLASS CONTEXT
  ###

  escapeFilePath = FSHelper.escapeFilePath

  getExtension:->
    [root, rest..., extension]  = @path.split '.'
    extension or= ''

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
      unless err isnt ""
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

  ###
  INSTANCE METHODS
  ###

  constructor:(options, data)->

    for own key, value of options
      @[key] = value
    super

    @kiteController = @getSingleton('kiteController')

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
