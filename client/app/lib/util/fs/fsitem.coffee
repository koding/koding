kd = require 'kd'
KDObject = kd.Object
FSHelper = require './fshelper'

# Base class for file instances
# Requires to work with Klient Kite
# and a provided Machine instance
#
module.exports = class FSItem extends KDObject

  # Commonly used helpers
  { escapeFilePath, handleStdErr } = FSHelper

  # Assign every option to instance
  constructor: (options, data) ->
    @[key] = value for own key, value of options
    super

  # Only static method of FSItem
  # Requires a valid machine object and a path to create
  # file on the server, type folder is also supported
  #
  # If requested path already exists, it generates new paths
  # eg, if /tmp/foo then /tmp/foo_1 will be created, and so on.
  @create = ({ path, type, machine, recursive, samePathOnly }, callback = kd.noop) ->

    unless path or machine
      kd.warn message = 'pass a path and machine to create a file'
      return callback { message }

    type      ?= 'file'
    recursive ?= no
    kite       = machine.getBaseKite()

    kite.init()

    .then ->

      plainPath = FSHelper.plainPath path

      method =
        if type is 'folder'
        then 'fsCreateDirectory'
        else 'fsWriteFile'

      options = {
        path            : plainPath
        content         : ''
        donotoverwrite  : yes
        recursive
      }

      kite.fsUniquePath { path: plainPath }

      .then (actualPath) ->

        if samePathOnly and actualPath isnt plainPath
          actualPath = plainPath

        createFileInstance = ->

          FSHelper.createFileInstance {
            path: actualPath
            type, machine
          }

        createFile = ->
          options.path = actualPath
          kite[method](options).then createFileInstance

        if samePathOnly
          if actualPath is plainPath
            createFile()
          else
            createFileInstance()
        else
          createFile()

      .nodeify callback

  ## Instance Level ##

  # Helper to get corresponding kite
  # TODO: add check kite state functionality
  getKite: -> @machine.getBaseKite()

  # Copy file instance to provided target folder
  copy: (folderPath, callback) ->

    @emit 'fs.job.started'

    folderPath = folderPath.replace /\/$/, ''
    folderPath = FSHelper.plainPath "#{folderPath}/#{@name}"

    kite = @getKite()
    file = null

    kite.init().then =>

      kite.fsUniquePath { path: folderPath }

      .then (actualPath) =>

        command = "cp -R #{ escapeFilePath @getPath() } #{ escapeFilePath actualPath }"

        kite.exec({ command })

        .then (result) ->
          cb = handleStdErr()
          cb result, 'cp'

    .nodeify(callback)

    .finally =>

      @emit 'fs.job.finished'
      return file


  # Compress file with given type
  #
  # TODO: add more checks for type
  # TODO: add option for targetPath
  compress: (type, callback) ->

    @emit 'fs.job.started'

    kite = @getKite()

    path = FSHelper.plainPath "#{@getPath()}.#{type}"

    kite.init().then ->

      kite.fsUniquePath { path }

    .then (actualPath) =>

      command =
        if type is 'tar.gz'
          "cd #{escapeFilePath @parentPath};tar -pczf #{escapeFilePath actualPath} #{escapeFilePath @name}"
        else
          "cd #{escapeFilePath @parentPath};zip -r #{escapeFilePath actualPath} #{escapeFilePath @name}"

      kite.exec { command }

    .then (result) ->
      cb = handleStdErr()
      cb result, type

    .nodeify(callback)

    .finally =>
      @emit 'fs.job.finished'


  extract: (callback = -> ) ->

    @emit 'fs.job.started'

    kite = @getKite()

    tarPattern = /\.tar\.gz$/
    zipPattern = /\.zip$/

    path = @getPath()

    [isTarGz, extractFolder] = switch

      when tarPattern .test @name
        [yes, path.replace tarPattern, '']

      when zipPattern .test @name
        [no, path.replace zipPattern, '']

    type = if isTarGz then 'tar' else 'zip'

    kite.init()

    .then ->
      kite.fsUniquePath({ path: "#{ extractFolder }" })

    .then (actualPath) =>

      command =
        if isTarGz
          "cd #{escapeFilePath @parentPath};mkdir -p #{escapeFilePath actualPath};tar -zxf #{escapeFilePath @name} -C #{escapeFilePath actualPath}"
        else
          "cd #{escapeFilePath @parentPath};unzip -o #{escapeFilePath @name} -d #{escapeFilePath actualPath}"

      kite.exec({ command })

    .then (result) ->
      cb = handleStdErr()
      cb result, type

    .nodeify(callback)

    .finally =>
      @emit 'fs.job.finished'

  getExtension: -> FSHelper.getFileExtension @name

  getPath: -> FSHelper.plainPath @path

  isHidden: -> FSHelper.isHidden @name

  exists: (callback = kd.noop) ->

    kite = @getKite()

    kite.init().then =>

      kite.fsGetInfo { path: @getPath() }
      .then (info) -> info.exists

    .nodeify(callback)

  stat: (callback = kd.noop) ->

    kite = @getKite()

    kite.init().then =>

      kite.fsGetInfo { path: @getPath() }

    .nodeify(callback)

  remove: (callback, recursive = no) ->

    @emit 'fs.delete.started'

    kite = @getKite()

    kite.init().then =>

      kite.fsRemove { path: @getPath(), recursive }

    .nodeify(callback)

    .then =>
      @emit 'fs.delete.finished'

  moveOrRename: (toPath, callback) ->

    @emit 'fs.job.started'

    kite = @getKite()

    kite.init()

    .then =>

      kite.fsMove
        oldpath : @getPath()
        newpath : toPath

    .nodeify(callback)

    .then =>
      @emit 'fs.job.finished'


  rename: (newName, callback) ->

    @moveOrRename "#{FSHelper.getParentPath @getPath()}/#{newName}", callback

  move: (newPath, callback) ->

    @moveOrRename "#{FSHelper.plainPath newPath}/#{@name}", callback


  chmod: (options, callback) ->

    { recursive, permissions: mode } = options

    @mode = mode

    return callback? new Error 'no permissions passed'  unless mode?

    @emit 'fs.job.started'

    kite = @getKite()

    kite.init().then =>

      kite.fsSetPermissions {
        path: @getPath()
        recursive
        mode
      }

    .nodeify(callback)

    .then =>
      @emit 'fs.job.started'
