
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

  @copyOrMove:(sourceItem, targetItem, commandPrefix, callback)->
    sourceItem.emit "fs.job.started"

    kite = sourceItem.getKite()
  # Helper to get corresponding kite
  # TODO: add check kite state functionality
  getKite: -> @machine.getBaseKite()# kites.klient

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
