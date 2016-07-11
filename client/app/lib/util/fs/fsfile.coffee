kd = require 'kd'
Promise = require 'bluebird'
FSItem = require './fsitem'
FSHelper = require './fshelper'


module.exports = class FSFile extends FSItem

  constructor: ->
    super

    @on 'file.requests.saveAs', (contents, name, parentPath) =>
      @saveAs contents, name, parentPath

    @on 'file.requests.save', (contents) =>
      @save contents

    @localStorage = kd.getSingleton('localStorageController').storage 'Finder'
    @fileInfo     = @getLocalFileInfo()

  getLocalFileInfo: ->
    @localStorage.getValue(btoa kd.utils.utf8Encode FSHelper.plainPath @path) or {}

  setLocalFileInfo: (data = {}) ->
    @fileInfo[key] = value for own key, value of data
    @localStorage.setValue btoa(kd.utils.utf8Encode FSHelper.plainPath @path), @fileInfo

  removeLocalFileInfo: ->
    @localStorage.unsetKey btoa kd.utils.utf8Encode FSHelper.plainPath @path

  fetchContentsBinary: (callback) ->
    @fetchContents no, callback

  fetchRawContents: (callback) ->
    kite = @getKite()
    kite.init().then =>
      kite.fsReadFile { path: FSHelper.plainPath @path }
    .nodeify callback

  fetchContents: (useEncoding, callback) ->
    [callback, useEncoding] = [useEncoding, callback]  unless callback

    useEncoding ?= yes

    @emit 'fs.job.started'

    @fetchRawContents().then (response) =>

      content = atob response.content
      content = kd.utils.utf8Decode content  if useEncoding # Convert to String

      @emit 'fs.job.finished'

      return content

    .nodeify(callback)

  saveAs: (contents, name, parentPath, callback) ->

    @emit 'fs.saveAs.started'

    newPath = FSHelper.plainPath "#{parentPath}/#{name}"

    file = null

    kite = @getKite()

    kite.init()
    .then =>

      ok = kite.fsUniquePath({ path: "#{newPath}" })
      .then (actualPath) =>

        file = FSHelper.createFileInstance {
          path : actualPath
          @machine
        }

        ok = file.save contents, (err, response) =>
          callback err, file, this  if callback
          if err
            @emit 'fs.saveAs.failed', err
          else
            @emit 'fs.saveAs.finished', file, this

        return ok


  append: (contents, callback) ->
    @emit 'fs.append.started'

    # Convert to base64
    content = btoa contents

    kite = @getKite().init()

    .then =>

      @getKite().fsWriteFile {
        path    : FSHelper.plainPath @path
        content : btoa contents
        append  : yes
      }


    if callback?

      kite

        .then (response) =>
          callback null, response
          @emit 'fs.append.finished', null, response

        .catch (err) ->
          kd.warn err
          callback err
          @emit 'fs.append.finished', err

    else

      kite.then (response) =>
        @emit 'fs.append.finished', null, response
        Promise.cast response


  saveBinary: (contents, callback) ->

    info       = @getLocalFileInfo()
    chunkQueue = FSHelper.createChunkQueue contents, info.lastUploadedChunk
    total      = chunkQueue.length

    @setLocalFileInfo { totalChunks: total }

    @on 'ChunkUploaded', (response) =>
      loaded   = total - chunkQueue.length
      percent  = 100 * loaded / total
      @setLocalFileInfo { lastUploadedChunk: loaded }
      callback? null, response, { total, loaded, percent }

    @once 'AllChunksUploaded', =>
      @off 'ChunkUploaded'
      @removeLocalFileInfo()
      callback? null, { finished: yes }

    @once 'AbortRequested', =>
      @abortRequested = yes
      callback? null, { abort: yes }

    iterateChunks = =>

      unless chunkQueue.length
        @emit 'AllChunksUploaded'

      next = chunkQueue.shift()
      return unless next
      return if @abortRequested

      { skip, content, append } = next

      if skip
        callback null, {},
          percent: 100 * info.lastUploadedChunk / info.totalChunks
        iterateChunks()
        return

      kite = @getKite().init()
      .then =>

        @getKite().fsWriteFile {
          path: FSHelper.plainPath @path
          content, append
        }

      .then (res) =>
        @emit 'ChunkUploaded', res
        iterateChunks()

      .catch (err) ->
        callback? err  if err

    iterateChunks()  if chunkQueue.length > 0


  abort: -> @emit 'AbortRequested'


  isDummyFile: -> return @path.indexOf('localfile:/Untitled') is 0


  save: (contents = '', callback = null, useEncoding = yes) ->

    @emit 'fs.save.started'

    ok = @getKite().init()
    .then =>

      contents = kd.utils.utf8Encode contents  if useEncoding

      # Convert to base64
      content = btoa contents

      @getKite().fsWriteFile {
        path: FSHelper.plainPath @path
        content
      }

    ok
      .then (response) =>
        callback null, response  if callback
        @emit 'fs.save.finished', response

        return response

      .catch (err) =>
        callback err  if callback
        @emit 'fs.save.failed', err


  fetchPermissions: (callback) ->

    kite = @getKite()

    kite.init()

    .then =>

      kite.fsGetInfo { path: @getPath() }

    .nodeify (err, result) ->

      return callback err  if err
      { readable, writable, exists } = result
      callback null, { readable, writable, exists }
