kd = require 'kd'
helper = require './helper'

module.exports = class MemoryFsKite extends kd.Object

  createMapping = (api) ->
    map = {}
    map[rpcMethod] = method  for own method, rpcMethod of api
    return map

  constructor: (options = {}) ->

    super options

    @fs = helper.generateFileSystem(options.username)
    @api = createMapping options.api

  connect: ->
    @emit 'open'
    Promise.resolve()


  disconnect: ->
    @emit 'close'
    Promise.resolve()


  read: (path) -> @fs.readFileSync(path).toString()


  clientSubscribe: (args) ->
    { eventName, onPublish } = args
    kd.utils.defer -> onPublish { files: [] }

    Promise.resolve { id: 'memory-fs-kite' }


  fsReadDirectory: (args, callback) ->

    [{ path: base }] = args
    files = @fs.readdirSync(base).map (path) =>
      fullPath = [base, path].join '/'
      stat = @fs.statSync(fullPath)

      return if stat.isDirectory()
      then wrapDir path, fullPath
      else wrapFile path, fullPath, @read(fullPath).length

    Promise.resolve(Promise.all(files)).then (files) -> { files }


  fsReadFile: (args, callback) ->

    [{ path }] = args

    return wrapFileInstance @read(path)


  fsGetInfo: (args, callback) ->

    [{ path }] = args

    return wrapFile path, '', @read(path).length


  fsSetPermissions: (args, callback) -> Promise.resolve yes


  fsUniquePath: (args, callback) ->

    [{ path }] = args

    path = generateNewPath(path)  if @fs.existsSync(path)

    Promise.resolve path


  fsWriteFile: (args, callback) ->

    [{ path, content }] = args

    encrypted = atob content

    @fs.writeFileSync(path, new Buffer encrypted)

    Promise.resolve(encrypted.length)


  fsRemove: (args, callback) ->

    [{ path }] = args

    @fs.unlinkSync(path)

    Promise.resolve yes


  fsMove: (args, callback) ->

    [{ oldpath, newpath }] = args

    content = btoa @read oldpath
    @fsWriteFile([{ path: newpath, content }]).then =>
      @fsRemove([{ path: oldpath }])


  fsRename: (args...) -> @fsMove args...


  fsCreateDirectory: (args, callback) ->

    [{ path }] = args

    @fs.mkdirpSync path

    Promise.resolve yes


  webtermGetSessions: (args, callback) -> Promise.resolve []


  tell: (rpcMethod, args, callback) ->

    method = @api[rpcMethod]

    promise = if this[method]
    then this[method].call this, args, callback
    else Promise.reject(new Error "not implemented: #{rpcMethod}")

    return promise.catch (e) ->
      console.warn 'failing silently', e


wrapDir = (path, fullPath = '') -> Promise.resolve
  name: path,
  fullPath: fullPath,
  isDir: true,
  exists: true,
  size: 4096,
  mode: 2147484141,
  time: '2016-10-08T03:00:28.996121999Z',
  isBroken: false,
  readable: true,
  writable: false


wrapFile = (path, fullPath, length) -> Promise.resolve
  name: path,
  fullPath: fullPath,
  isDir: false,
  exists: true,
  size: length,
  mode: 777,
  time: '2016-10-08T03:00:28.996121999Z',
  isBroken: false,
  readable: true,
  writable: true


wrapFileInstance = (content) -> Promise.resolve { content: btoa content }
