
# Base class for file instances
# Requires to work with Klient Kite
# and a provided Machine instance
#
class FSItem extends KDObject

  # Commonly used helpers
  { escapeFilePath, handleStdErr } = FSHelper

  # Assign every option to instance
  constructor:(options, data)->
    @[key] = value for own key, value of options
    super

  # Only static method of FSItem
  # Requires a valid machine object and a path to create
  # file on the server, type folder is also supported
  #
  # If requested path already exists, it generates new paths
  # eg, if /tmp/foo then /tmp/foo_1 will be created, and so on.
  @create = ({ path, type, machine }, callback = noop)->

    unless path or machine
      warn message = "pass a path and machine to create a file"
      return callback { message }

    type ?= "file"
    kite  = machine.getBaseKite()

    kite.vmOn()

    .then ->

      plainPath = FSHelper.plainPath path

      method =
        if type is "folder"
        then "fsCreateDirectory"
        else "fsWriteFile"

      options =
        path            : plainPath
        content         : ''
        donotoverwrite  : yes

      kite.fsUniquePath path: plainPath

      .then (actualPath) ->

        options.path = actualPath

        kite[method](options).then (stat) ->

          FSHelper.createFileInstance {
            path: actualPath
            type, machine
          }

      .nodeify callback

  ## Instance Level ##

  # Helper to get corresponding kite
  # TODO: add check kite state functionality
  getKite: -> @machine.getBaseKite()# kites.klient

  # Copy file instance to provided target folder
  copy: (folderPath, callback)->

    @emit "fs.job.started"

    folderPath = folderPath.replace /\/$/, ''
    folderPath = "#{folderPath}/#{@name}"

    kite = @getKite()
    file = null

    kite.vmOn().then =>


      kite.fsUniquePath { path: folderPath }

      .then (actualPath) =>

        command = "cp -R #{ escapeFilePath @getPath() } #{ escapeFilePath actualPath }"

        kite.exec({command})

        .then(handleStdErr())

        .then ->

          return FSHelper.createFileInstance
            path        : actualPath
            parentPath  : folderPath
            name        : @name
            type        : @type
            machine     : @machine

    .nodeify(callback)

    .finally =>

      @emit "fs.job.finished"
      return file


  # Compress file with given type
  #
  # TODO: add more checks for type
  # TODO: add option for targetPath
  compress: (type, callback)->

    @emit "fs.job.started"

    kite = @getKite()

    path = FSHelper.plainPath "#{@getPath()}.#{type}"

    kite.vmOn().then ->

      kite.fsUniquePath { path }

    .then (actualPath) =>

      command =
        if type is "tar.gz"
          "tar -pczf #{escapeFilePath actualPath} #{escapeFilePath @getPath()}"
        else
          "zip -r #{escapeFilePath actualPath} #{escapeFilePath @getPath()}"

      kite.exec { command }

    .then(handleStdErr())

    .nodeify(callback)

    .finally =>
      @emit "fs.job.finished"


  @extract: (callback = (->)) ->

    @emit "fs.job.started"

    kite = @getKite()

    tarPattern = /\.tar\.gz$/
    zipPattern = /\.zip$/

    path = @getPath()

    [isTarGz, extractFolder] = switch

      when tarPattern .test @name
        [yes, path.replace tarPattern, '']

      when zipPattern .test @name
        [no, path.replace zipPattern, '']

    kite.vmOn()

    .then ->
      kite.fsUniquePath(path: "#{ extractFolder }")

    .then (actualPath) =>

      command =
        if isTarGz
          "cd #{escapeFilePath @parentPath};mkdir -p #{escapeFilePath actualPath};tar -zxf #{escapeFilePath @name} -C #{escapeFilePath actualPath}"
        else
          "cd #{escapeFilePath @parentPath};unzip -o #{escapeFilePath @name} -d #{escapeFilePath actualPath}"

      kite.exec({command})

    .then(handleStdErr())

    .then =>

      file = FSHelper.createFileInstance {
        path            : actualPath
        parentPath      : @parentPath
        type            : 'folder'
        machine         : @machine
      }

      return file

    .nodeify(callback)

    .finally =>
      @emit "fs.job.finished"

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
