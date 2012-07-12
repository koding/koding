class CommandParser
  
  @parse = (parentPaths, response) ->
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
        data.push CommandParser._parseFile parentPath, line
    data
    
  @_parseFile = (parentPath, str) ->
    [permissions, size, user, group, mode, date, time, timezone, rest...] = str.replace(/\t+/gi, ' ').replace(/\s+/ig, ' ').split ' '
    
    #make the time gmt
    unixTime  = Date.parse "#{date}T#{time}"
    date      = new Date unixTime
    hoursDiff = parseInt("#{timezone[1]}" + "#{timezone[2]}", 10)
    minsDiff  = parseInt("#{timezone[3]}" + "#{timezone[4]}", 10)
    hoursDiff = hoursDiff*60*60*1000
    minsDiff  = minsDiff*60*1000
    totalDiff = hoursDiff + minsDiff
    totalDiff = if timezone[0] is '-' then -totalDiff else totalDiff
    date.setTime date.getTime() + totalDiff
    
    type = CommandParser.fileTypes[permissions[0]]
    if type is 'symLink'
      [path, linkPath] = (rest.join ' ').split /\ ->\ \//
    else
      path = rest.join ' '

    mode      = __utils.symbolsPermissionToOctal(permissions)
    path      = parentPath + '/' + path
    path      = if type is 'folder' then path.substr(0, path.length - 1) else path
    
    result    = {
      size
      user
      group
      date
      mode
      type
      parentPath
      path        : path
      name        : path.split('/').pop()
    }
  
  @createFile = (path, type)->
    result = {
      mode: '666'
      path
      name : path.split('/').pop()
      type
    }
  
  @isValidFileName = (name) ->
    /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test(name)
    
  @escapeFilePath = (name) ->
    name  = name.replace /\'/g, '\\\''
    name  = name.replace /\"/g, '\\"'
    ' "' + name + '" '
  
  @fileTypes =
    '-' : 'file'
    d : 'folder'
    l : 'symLink'
    p : 'namedPipe'
    s : 'socket'
    c : 'characterDevice'
    b : 'blockDevice'
    D : 'door'
  
  @parseStat = (fileData, response)->
    permissions = response.match(/Access: \([0-9]*\/(..........)/)[1]
    fileData.mode = __utils.symbolsPermissionToOctal permissions
