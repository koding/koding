class FSFolder extends FSFile

  constructor: ->
    { @stack } = new Error
    super

  fetchContents:(callback, dontWatch=yes)->
    { treeController } = @getOptions()

    @osKite.vmStart()

    .then =>
      @osKite.fsReadDirectory
        path      : FSHelper.plainPath @path
        onChange  : if dontWatch then null else (change) =>
          FSHelper.folderOnChange {
            @vmName
            @path
            change
            treeController
            @osKite
          }

    .then (response) =>
      files =
        if response?.files?
        then FSHelper.parseWatcher {
          @vmName
          parentPath: @path
          files: response.files
          treeController
          @osKite
        }
        else []
      callback null, files

    .catch (err) ->
      callback err

    .then =>
      @emit 'fs.job.finished'


  save:(callback)->

    @emit "fs.save.started"

    @osKite.vmStart()

    .then =>
      @vmController.fsCreateDirectory({
        path: FSHelper.plainPath @path
      })

    .then (response) =>
      callback null, response
      @emit "fs.save.finished", null, response

    .catch (err) =>
      warn err
      callback err
      @emit "fs.save.finished", err

  saveAs:(callback)->
    log 'Not implemented yet.'
    callback? null

  remove:(callback)->
    @off 'fs.delete.finished'
    @on  'fs.delete.finished', =>
      return  unless finder = KD.getSingleton 'finderController'
      finder.stopWatching @path

    super callback, yes

  registerWatcher:(response)->
    {@stopWatching} = response
    finder = KD.getSingleton 'finderController'
    return unless finder
    finder.registerWatcher @path, @stopWatching  if @stopWatching