kd = require 'kd'
FSFile = require './fsfile'
FSHelper = require './fshelper'

module.exports = class FSFolder extends FSFile

  fetchContents: (dontWatch, callback) ->

    [callback, dontWatch] = [dontWatch, callback]  unless callback?

    dontWatch ?= yes

    { treeController } = @getOptions()

    kite = @getKite()

    kite.init()

    .then =>

      kite.fsReadDirectory
        path      : FSHelper.plainPath @path
        onChange  : if dontWatch then null else (change) =>
          FSHelper.folderOnChange { @path, change, @machine, treeController }

    .then (response) =>

      if response?.files?

        FSHelper.parseWatcher {
          parentPath : @path
          files      : response.files
          treeController, @machine
        }

    .nodeify(callback)

    .then =>
      @emit 'fs.job.finished'


  # save:(callback) ->

  #   @emit "fs.save.started"

  #   @getKite().init()

  #   .then =>
  #     @vmController.fsCreateDirectory {
  #       path: FSHelper.plainPath @path
  #     }

  #   .nodeify (err, response) ->
  #     callback null, response
  #     @emit "fs.save.finished", null, response

  saveAs: (callback) ->
    kd.log 'Not implemented yet.'
    callback? null

  remove: (callback) ->
    @off 'fs.delete.finished'
    @on  'fs.delete.finished', =>
      finder = @treeController.delegate
      finder?.stopWatching @path

    super callback, yes

  registerWatcher: (response) ->
    { @stopWatching } = response
    finder = @treeController.delegate
    finder?.registerWatcher @path, @stopWatching  if @stopWatching
