class FSHelper

  systemFilesRegExp =
    ///
    \s\.cagefs|\s\.tmp
    ///

  parseFile = (parentPath, outputLine) ->

    [permissions, size, user, group, mode, date, time, timezone, rest...] = outputLine.replace(/\t+/gi, ' ').replace(/\s+/ig, ' ').split ' '

    if type is 'symLink'
      [path, linkPath] = (rest.join ' ').split /\ ->\ \//
    else
      path = rest.join ' '

    createdAt = getDateInstance date, time, timezone
    type      = FSHelper.fileTypes[permissions[0]]
    mode      = __utils.symbolsPermissionToOctal(permissions)
    path      = parentPath + '/' + path
    path      = if type is 'folder' then path.substr(0, path.length - 1) else path
    name      = getFileName path

    if type is 'folder'
      if /^\/Users\/(.*)\/RemoteDrives(|\/([^\/]+))$/gm.test path
        type = 'mount'

    return { size, user, group, createdAt, mode, type, parentPath, path, name }

  getDateInstance = (date, time, timezone) ->

    unixTime  = Date.parse "#{date}T#{time}"
    date      = new Date unixTime
    hoursDiff = parseInt("#{timezone[1]}" + "#{timezone[2]}", 10)
    minsDiff  = parseInt("#{timezone[3]}" + "#{timezone[4]}", 10)
    hoursDiff = hoursDiff*60*60*1000
    minsDiff  = minsDiff*60*1000
    totalDiff = hoursDiff + minsDiff
    totalDiff = if timezone[0] is '-' then -totalDiff else totalDiff
    date.setTime date.getTime() + totalDiff
    return date

  @parseLsOutput = (parentPaths, response) ->
    # log "ls response",response
    data = []
    return data unless response
    strings = response.split '\n\n'
    for string in strings
      lines = string.split '\n'
      if strings.length > 1
        [parentPath, itemCount] = lines.splice(0,4)
        parentPath = parentPath.replace /\:$/, ''
      else
        [itemCount] = lines.splice(0,3)
        parentPath = parentPaths[0]
      for line in lines when line
        unless line[0] in ['l', '?'] # broken symlinks has l type and it can be ? in someway
          unless systemFilesRegExp.test line
            data.push FSHelper.createFile parseFile parentPath, line
    data

  @registry = {}

  @register = (file)->

    @setFileListeners file
    @registry[file.path] = file

  @deregister = (file)->

    delete @registry[file.path]

  @updateInstance = (fileData)->

    for prop, value of fileData
      @registry[fileData.path][prop] = value

  @setFileListeners = (file)->

    file.on "fs.rename.finished", =>


  @getFileNameFromPath = getFileName = (path)->

    path.split('/').pop()

  @trimExtension = (path)->

    name = getFileName path
    name.split('.').shift()

  @createFileFromPath = (path, type = "file")->

    return warn "pass a path to create a file instance" unless path
    parentPath = __utils.getParentPath path
    name       = @getFileNameFromPath path
    return @createFile { path, parentPath, name, type }

  @createFile = (data)->

    unless data and data.type and data.path
      return warn "pass a path and type to create a file instance"

    if @registry[data.path]
      instance = @registry[data.path]
      @updateInstance data
    else
      constructor = switch data.type
        when "folder" then FSFolder
        when "mount"  then FSMount
        when "symLink" then FSFolder
        else FSFile

      instance = new constructor data
      @register instance

    return instance

  @isValidFileName = (name) ->

    return /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test name

  @isEscapedPath = (path) ->
    return /^\s\"/.test path

  @escapeFilePath = (name) ->

    return " \"#{name.replace(/\'/g, '\\\'').replace(/\"/g, '\\"')}\" "

  @unescapeFilePath = (name) ->

    return name.replace(/^(\s\")/g,'').replace(/(\"\s)$/g, '').replace(/\\\'/g,"'").replace(/\\"/g,'"')

  @fileTypes =

    '-' : 'file'
    d   : 'folder'
    l   : 'symLink'
    p   : 'namedPipe'
    s   : 'socket'
    c   : 'characterDevice'
    b   : 'blockDevice'
    D   : 'door'

  @parseStat = (fileData, response)->

    permissions = response.match(/Access: \([0-9]*\/(..........)/)[1]
    fileData.mode = __utils.symbolsPermissionToOctal permissions

KD.classes.FSHelper = FSHelper
