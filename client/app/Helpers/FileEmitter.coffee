class FS extends KDObject
  constructor: ->
    super
    @command    = new Command
    @_register  = {}
    
    @setListeners()

  setListeners: ->
    @_compressListeners()
    @_makePublicListeners()
    
  watch: ({dir}) ->
    bongo.api.FSWatcher.watch {dir}
    
  unwatch: ({dir}) ->
    bongo.api.FSWatcher.unwatch {dir}
    
  get: (path) ->
    @_register[path]
    
  register: (item) ->
    if item.path
      # log "added to register #{item.path}"
      @_register[item.path] = item
    else
      warn 'FS::register item didnt have path, cant register file'
  
  reset: ()->
    for path, item of @_register
      item.destroy()
    
  remove: (item) ->
    if @_register[item.path]
      # log "removed from register #{item.path}"
      delete @_register[item.path]
    
  create: (rawData) ->
    if @_register[rawData.path]
      return @_register[rawData.path]
    else
      constructor = if rawData.type is 'mount'
        Mount
      else if rawData.type is 'folder'
        Folder
      else if rawData.type is 'file'
        File
      else 
        warn "FS::create didnt get type property, returning File instance"
        rawData.type = 'file'
        File
      item = new constructor {}, rawData
      item.id or= __utils.getUniqueId() #giving unique id
      @register item
      item
    
  #compress placed on FS as we cant tight it to folder
  #files for compressing could be from few places of file system
  compress: (files) ->
    @emit 'compress.start', {files}
    
  makePublic: (files) ->
    @emit 'makePublic.start', {files}
    
  _makePublicListeners: ->
    @on 'makePublic.start', ({files}) =>
      @command.emit 'fs.makePublic.start', files
      
    @command.on 'fs.makePublic.finish', (error, data, url) =>
      @emit 'makePublic.finish', {error, url}
    
  _compressListeners: ->
    @on 'compress.start', ({files}) =>
      paths = for file in files
        file.path
      @command.emit 'fs.compress.start', {paths}
      
    @command.on 'fs.compress.finish', (error, data, resultFile) =>
      unless error
        file = @create resultFile
        file.getParent().appendSubItem file
        
      @emit 'compress.finish', {error, file}
  
  saveToDefaultCodeSnippetFolder:(title, contents, callback)->
    dirPath = "/Users/#{KD.whoami().profile.nickname}/CodeSnippets"
    @command.run
      toDo      :
        command : "mkdir -p #{dirPath}"
    , (error, response)=>
      if error then callback error
      else
        @command.safePath 
          filePath : "#{dirPath}/#{title}"
        , (error, safePath)->
          if error then callback error
          else
            @command.uploadFile {contents}, (error, url)=>
              if error
                callback error 
              else 
                @command.run 
                  toDo      :
                    command : "curl -L #{url}>#{safePath}"
                , (error, response)->
                  callback error, safePath
  

class AbstractItem extends KDObject
  constructor: (options, data) ->
    super
    @command  = new Command
    @fs       = KD.getSingleton "fs"
    @setListeners()
    
    @_locks = {instances: [], messages: []}
    
    for key, value of data
      @[key] = value
      
  isFile: ->
    @type is 'file'
    
  isFolder: ->
    @type is 'folder'
    
  isMount: ->
    @type is 'mount'
      
  remove: (callback) ->
    result = @_canRemove()
    unless result.canRemove
      @emit 'remove.finish', {error: "Can not remove #{@name}. Reason: #{result.item.path}, #{result.reason[0]}"}
    else    
      @emit 'remove.start'
      if callback
        @on 'remove.finish', callback
      
  _canRemove: () ->
    checker = (item) ->
      if item._locks.instances.length >= 1
        return {canRemove: no, reason: item._locks.messages, item}
      else
        if item.isFolder()
          for subItem in item.subItems
            return checker subItem
            
    canI = checker @
    unless canI
      {canRemove: yes}
    else
      canI
      
  lock: (instance, message) ->
    index = @_locks.instances.indexOf instance
    if index is -1
      @_locks.instances.push instance
      @_locks.messages.push message
    else
      warn 'File already locked by ', instance
    
  unLock: (instance) ->
    index = @_locks.instances.indexOf instance
    
    if index > -1
      @_locks.instances.splice index, 1
      @_locks.messages.splice index, 1
    
      
  # parents are taken based on file path
  # file paths should be kept at actual state
  getParent: ->
    (pathInfo = @path.split('/')).pop()
    path = pathInfo.join '/'
    @fs.get path
    
  #accepts Folder instance
  copyTo: (folder, callback) ->
    @emit 'copy.start', {to: folder}
    @once 'copy.finish', callback
    
  
  renameTo: (newName) ->
    @emit 'rename.start', {name: newName}
    
    
  moveTo: (folder, callback) ->
    @emit 'move.start', {to: folder}
    if callback
      @once 'move.finish', callback
      
  _renameListeners: ->
    @on 'rename.start', ({name}) =>
      @command.emit 'fs.rename.start', {fileData: @, newName: name}
      
    @command.on 'fs.rename.finish', (error, data, result) =>
      #we have to fix all subitems paths
      fix = (folder) ->
        if folder.type is 'folder'
          for item in folder.subItems
            @fs.remove item
            item.path = folder.path + '/' + item.name
            @fs.register item
            fix item
            
      @fs.remove @
      @path = @getParent().path + '/' + data.newName
      @name = data.newName
      @fs.register @
      # log 'file paths fixer launched'
      fix @
      # log 'fixer done, good job!'
      
      @emit 'rename.finish', {error}
      
    @on 'rename.finish', =>
      # log 'finished rename at all'
    
  _removeListeners: ->
    @on 'remove.start', =>
      @command.emit 'fs.remove.start', {path: @path}

    @command.on 'fs.remove.finish', (error, data, response) =>
      unless error
        parent = @getParent()
        parent.removeSubItem @ #garbage collector included in removeSubItem method
      
      @emit 'remove.finish', {error, response}
      
  destroy: ->
    @fs.remove @
    @emit 'destroy'
    super
      
  _moveListeners: ->
    @on 'move.start', ({to}) =>
      @command.emit 'fs.move.start', {items: [@], moveTo: to, moveToFolder: to}
      
    @command.on 'fs.move.finish', (error, data, result) =>
      @emit 'move._finish', {error, data, result}
      
    @on 'move._finish', (options) =>
      {result, data, error} = options
      {items, moveToFolder} = data
      unless error
        for item in items
          item.getParent().removeSubItem item
          moveToFolder.appendSubItem item
          if item.isFolder()
            item._listed    = no
            item._subListed = no
            item.list()
          
      @emit 'move.finish', {error}
    
  _copyListeners: ->
    @on 'copy.start', ({to}) =>
      @command.emit 'fs.copy.start', {items: [@], copyTo: to, copyToFolder: to}

    @command.on 'fs.copy.finish', (error, data, result) =>
      @emit 'copy._finish', {error, data, result}

    @on 'copy._finish', (options) =>
      {result, data, error} = options
      for resultItem in result
        newFile       = @fs.create resultItem
        newFile.inFS  = yes
        data.copyToFolder.appendSubItem newFile
        if newFile.isFolder()
          newFile.list()
      @emit 'copy.finish'
      
  setListeners: ->
    @_copyListeners()
    @_moveListeners()
    @_removeListeners()
    @_renameListeners()
    
class Folder extends AbstractItem
  constructor: ->
    super
    @subItems = []
    
  appendSubItem: (item) ->
    if item in @subItems
      return warn 'item already in subitems list'
      
    newPath = @path + '/' + item.name
    if item.path isnt newPath
      @fs.remove item
      item.path = newPath
      item.emit 'path.changed'
      item.id = __utils.getUniqueId() #do I need to change its id?
      @fs.register item
    
    @emit 'item.appear', item
    @subItems.push item
    
  refresh: ->
    for item in @subItems.slice(0)
      @removeSubItem item
      
    @_listed    = no
    @_subListed = no
    @list()
    
  onNewItem: (callback) ->
    @on 'item.appear', callback
    
  removeSubItem: (item) ->
    index = @subItems.indexOf item
    if index > -1
      @subItems.splice index, 1
      @fs.remove item

      item.emit 'item.disappear'
      
      if item.isFolder() # destroy all subitems info
        for subItem in item.subItems.slice(0)
          item.removeSubItem subItem
      
  createFolder: (callback) ->
    @emit 'folder.create.start'
    if callback
      @once 'folder.create.finish', callback
      
  createFile: (callback) ->
    @emit 'file.create.start'
    if callback
      @once 'file.create.finish', callback
      
  list: (callback) ->
    for item in @subItems.slice(0)
      @removeSubItem item
      
    @_listed    = yes
    @_subListed = yes
    @emit 'list.start', {}
    @once 'list.finish', callback if callback
    
  setListeners: ->
    super
    
    @_listListeners()
    @_createFolderListeners()
    @_createFileListeners()

  _listListeners: ->
    # debugger
    # log "_listListeners"
    @on 'list.start', =>
      @_fetchedFiles = 'in process'
      @command.emit 'fs.multiLs.start', {paths: [@path]}
      
    @command.on 'fs.multiLs.finish', (error, data, files) =>
      unless error
        files = for file in files
          file.inFS = yes
          item = @fs.create file
          @appendSubItem item
          item
      
        @_fetchedFiles = yes
        @emit 'list.finish', files
      else
        kiteController = @getSingleton('kiteController')
        kiteController.propagateEvent KDEventType : "KiteNotAvailable", error
        # @emit 'list.finish', []
        @emit 'list.failed', []
    
  _createFileListeners: ->
    @on 'file.create.start', =>
      newPath = @path + '/NewFile.txt'
      @command.emit 'fs.safePath.start', {filePath: newPath}
      @command.once 'fs.safePath.finish', (error, data, safePath) =>
        # log 'safe path', error, data, safePath
        if error
          @emit 'file.create.finish', {error}
        else
          @command.emit 'fs.createFile.start', {path: safePath}
          
    @command.on 'fs.createFile.finish', (error, data, newFile) =>
      unless error
        file = @fs.create newFile
        file.inFS = yes
        file.getParent().appendSubItem file
        
      @emit 'file.create.finish', {error,file}
      
    
  _createFolderListeners: ->
    @on 'folder.create.start', =>
      newPath = @path + '/NewFolder'
      @command.emit 'fs.safePath.start', {filePath: newPath}
      @command.once 'fs.safePath.finish', (error, data, safePath) =>
        # log 'safe path', error, data, safePath
        if error
          @emit 'folder.create.finish', {error}
        else
          @command.emit 'fs.createFolder.start', {path: safePath}
        
    @command.on 'fs.createFolder.finish', (error, data, newFolder) =>
      unless error
        folder = @fs.create newFolder
        folder.getParent().appendSubItem folder
        
      @emit 'folder.create.finish', {error,folder}
    

class Mount extends Folder

class File extends AbstractItem
  
  @fromPath =(path)-> KD.getSingleton('fs').create CommandParser.createFile path
  
  constructor: () ->
    super
    @modified = no
    @_savedContents = ''
    
  revertToSavedState: ->
    @setContents @_savedContents
    
  setContents: (contents) ->
    if @_savedContents isnt contents
      @modified  = yes
    else
      @modified  = no
    @contents   = contents
    @emit 'change', {@modified}
    
  save: (callback) ->
    @emit 'save.start'
    if callback
      @once 'save.finish', callback
    
  isModified: ->
    @modified
    
  isNew: ->
    not @inFS
    
  extract: ->
    @emit 'extract.start'
    
  getContents: (callback) ->
    if @isNew() #file is not in fs there is no need to fetch
      return callback @contents
      
    unless @_fetched
      #FIXME wRONG!! --sah 2/15/12
      @on 'fetch.finish', callback
      unless @_fetchFired
        @_fetchFired = yes
        @emit 'fetch.start'
    else
      callback @contents
  
  getExtension: ->
    [root, rest..., extension]  = @path.split '.'
    extension or= ''
      
  _extractListeners: ->
    @on 'extract.start', =>
      @command.emit 'fs.extract.start', {path: @path}
      
    @command.on 'fs.extract.finish', (error, data, folder) =>
      # log 'finished', error, data, folder
      unless error
        folder = @fs.create folder
        folder.getParent().appendSubItem folder
        folder.list()
        
      @emit 'extract.finish', {error}
    
  _fetchListeners: ->
    @on 'fetch.start', () =>
      @command.emit 'fs.fetchFile.start', {path: @path}
      
    @command.on 'fs.fetchFile.finish', (error, data, contents) =>
      @_fetched = yes
      @contents        = contents
      @_savedContents  = contents
      @emit 'fetch.finish', contents

  _saveListeners: ->
    @on 'save.start', =>
      @command.emit 'fs.saveFile.start', {newFile: @, path: @path}
      
    @command.on 'fs.saveFile.finish', (error, data, result) =>
      unless error
        if @isNew()
          @getParent().appendSubItem @
        @inFS = yes
        @_savedContents = @contents
        @setContents @contents
      else
        @emit 'save.error', error
      
      @emit 'save.finish', {error}
    
  setListeners: ->
    super
    @_fetchListeners()
    @_saveListeners()
    @_extractListeners()
    