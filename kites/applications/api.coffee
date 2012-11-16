## Gokmen Goksel ~ Koding Inc. 2012

# Kite requirements
Kite           = require 'kite-amqp'
config         = require './config'

# Logger
log4js         = require 'log4js'
log            = log4js.getLogger("[#{config.name}]")

# Custom Libraries for this Kite
{exec}         = require 'child_process'
fs             = require 'fs'
fse            = require 'fs.extra'
mkdirp         = require 'mkdirp'
nodePath       = require 'path'
async          = require 'async'
pistachioc     = require 'pistachio-compiler'

# Coffee-Script
coffee         = require 'coffee-script'

# Execute Command
# executeCommand = require '../sharedHosting/executecommand'
sharedHosting = require '../sharedHosting'

console.log sharedHosting

executeCommand = sharedHosting.executeCommand.bind sharedHosting

# Utilities
{normalizeUserPath,
 createAppsDir,
 safeForUser,
 escapePath,
 makedirp,
 slugify,
 chownr,
 getIds,
 KodingError,
 AuthorizationError} = require './utils.coffee'

# Dummy-Admins
dummyAdmins = ["devrim", "sinan", "chris", "aleksey", "gokmen", "arvidkahl"]

compileScript = (scriptPath, callback)->

  # log.info "Compiling this:", scriptPath

  fs.exists scriptPath, (exists)->
    if not exists
      log.warn "Scriptfile '#{scriptPath}' is not exists, ignoring."
      callback false
    else
      fs.readFile scriptPath, (err, scriptContent)->
        if err then callback err, {file: scriptPath, error: new KodingError 'Parsing, file failed.'}
        else if /.coffee$/.test scriptPath
          compiledWell = yes
          try
            js = coffee.compile scriptContent+'', { bare : yes }
          catch e
            compiledWell = no
            callback yes, {file: scriptPath, error: new KodingError('Compile failed', e.message)}
          if compiledWell
            callback err, {file: scriptPath, code: js}
        else if /.js$/.test scriptPath
          callback err, {file: scriptPath, code: scriptContent}
        else
          callback err, {file: scriptPath, error: new KodingError 'Nothing to do with that file.'}

module.exports = new Kite 'applications'

  installApp: (options, callback)->

    {username, owner, appPath, appName, version} = options

    version   or= 'latest'
    kpmAppPath  = escapePath "/opt/Apps/#{owner}/#{appName}/#{version}", yes
    userAppPath = escapePath appPath

    if kpmAppPath.indexOf("/opt/Apps/") isnt 0 or not safeForUser username, userAppPath
      callback? new AuthorizationError username
      return false

    fs.exists kpmAppPath, (exists)->
      if not exists then callback? new KodingError "App files not found! Install cancelled.", kpmAppPath
      else
        executeCommand {username, command: "mkdir -p #{userAppPath}"}, (err)->
          if err then new KodingError "Cannot create Application directory", userAppPath
          else
            fse.copy "#{kpmAppPath}/index.js", "#{userAppPath}/index.js", (err)->
              fse.copy "#{kpmAppPath}/.manifest", "#{userAppPath}/.manifest", (err)->
                chownr {username, path: userAppPath}, callback

  downloadApp: (options, callback)->

    {username, owner, appName, version, appPath} = options

    version   or= 'latest'
    kpmAppPath  = escapePath "/opt/Apps/#{owner}/#{appName}/#{version}", yes
    userAppPath = escapePath appPath
    backupPath  = "#{appPath}.org.#{(Date.now()+'').substr(-4)}"

    if kpmAppPath.indexOf("/opt/Apps/") isnt 0 or not safeForUser username, userAppPath
      callback? new AuthorizationError username
      return false

    fs.exists kpmAppPath, (exists)->
      if not exists then callback? new KodingError "App files not found! Download cancelled."
      else
        executeCommand {username, command: "mv #{userAppPath} #{backupPath}"}, ->
          fse.copyRecursive kpmAppPath, userAppPath, (err)->
            if err then callback new KodingError "Downloading app source failed."
            else
              chownr {username, path: userAppPath}, callback

  copyAppSkeleton:(options, callback)->
    {username, appPath, type} = options

    appPath = normalizeUserPath(username, escapePath "#{appPath}/")
    type = "blank" if not type in ["blank", "sample"]

    if safeForUser username, appPath
      getIds options.username, (err, {uid, gid})->
        if err
          log.error err
          callback err
        else
          # FIXME GG when you fix copy recursive
          fse.copy "/opt/Apps/.defaults/#{type}/README", "#{appPath}/README", (err)->
            fse.copy "/opt/Apps/.defaults/#{type}/index.coffee", "#{appPath}/index.coffee", (err)->
              fse.copyRecursive "/opt/Apps/.defaults/#{type}/resources", "#{appPath}/resources", (err)->
                if err
                  log.error err
                  callback err
                else
                  chownr {uid, gid, path : "#{appPath}/"}, (err)->
                    callback err
                    if not err then log.info "User : [#{username}] created a new app!"
                    else log.error err
    else
      callback new AuthorizationError username

  compileApp: (options, callback)->

    {username, appPath} = options

    appRootPath = escapePath normalizeUserPath username, appPath

    if not safeForUser username, appRootPath
      callback new AuthorizationError username
      return no

    fs.exists appRootPath, (exists)=>
      if not exists then callback new KodingError "Application folder doesn't exists!", appRootPath
      else
        fs.readFile nodePath.join(appRootPath, '.manifest'), (err, manifestRaw)=>
          if err then callback new KodingError "Failed to read Manifest file!", err
          else
            manifestIsSafe = yes
            try
              manifest = JSON.parse manifestRaw
            catch e
              manifestIsSafe = no
              callback new KodingError "Parsing manifest failed.", e
            if manifestIsSafe
              if appRootPath.replace(/^\/|\/$/g, '') isnt normalizeUserPath(username, manifest.path).replace(/^\/|\/$/g, '')
                callback new KodingError "Paths are different in manifest, exiting."
                log.error appRootPath, normalizeUserPath username, manifest.path
              else
                {source, name} = manifest
                {blocks}       = source
                orderedBlocks  = []
                blockStrings   = []
                asyncStack     = []

                for blockName, blockOptions of blocks
                  blockOptions.name = blockName
                  if blockOptions.order? and not isNaN(order = parseInt(blockOptions.order, 10))
                    orderedBlocks[order] = blockOptions
                  else
                    orderedBlocks.push blockOptions

                if manifest.devMode
                  appResourceRoot = "/Users/#{username}/Sites/#{username}.koding.com/website/.applications"
                  appDevModePath  = escapePath nodePath.join appResourceRoot, slugify manifest.name

                  if safeForUser username, appDevModePath
                    asyncStack.push (cb)=>
                      executeCommand {username, command:"rm -rf #{appDevModePath}"}, =>
                        executeCommand {username, command:"mkdir -p #{appResourceRoot}"}, =>
                          executeCommand {username, command:"ln -s #{appRootPath} #{appDevModePath}"}, -> cb()

                orderedBlocks.forEach (block)=>

                  if block.pre
                    asyncStack.push (cb)=> compileScript nodePath.join(appRootPath, block.pre), cb

                  if block.files
                    {files} = block
                    files.forEach (file, index)=>
                      if "object" is typeof file
                        for fileName, fileExtras of file
                          do =>
                            if fileExtras.pre
                              asyncStack.push (cb)=> compileScript nodePath.join(appRootPath, fileExtras.pre), cb
                            asyncStack.push (cb)=> compileScript nodePath.join(appRootPath, fileName), cb
                            if fileExtras.post
                              asyncStack.push (cb)=> compileScript nodePath.join(appRootPath, fileExtras.post), cb
                      else
                        asyncStack.push (cb)=> compileScript nodePath.join(appRootPath, file), cb
                  if block.post
                    asyncStack.push (cb)=> compileScript nodePath.join(appRootPath, block.post), cb

                async.parallel asyncStack, (error, result)=>

                  _has_code = no
                  _compile_errors = []
                  _final  = "// Compiled by Koding Servers at #{Date()} in server time\n\n"
                  _final += "(function() {\n\n/* KDAPP STARTS */"
                  result.forEach (output)=>
                    if output and output.file
                      _final += "\n\n/* BLOCK STARTS /Source: #{output.file} */\n\n"
                      if output.error? or not output.code?
                        _final += "//couldn\'t compile the hunk! -- check console log"
                        output.error.file = output.file
                        _compile_errors.push output.error
                      else
                        _has_code = yes
                        _final += output.code+''
                      _final += "\n\n/* BLOCK ENDS */\n\n"
                  _final += "/* KDAPP ENDS */\n\n}).call();"

                  log.info "Compile finished for #{appRootPath}"

                  if _compile_errors.length > 0
                    callback new KodingError "Compile finished with errors", _compile_errors[0]

                  else if _has_code
                    compiledFilePath = nodePath.join appRootPath, 'index.js'
                    _pistachio_compiled = yes
                    try
                      _final = pistachioc _final
                    catch e
                      _pistachio_compiled = no
                      callback new KodingError "Template engine failed to compile app", e.message

                    if _pistachio_compiled
                      fs.writeFile compiledFilePath, _final, (err)->
                        if err then callback new KodingError "App compiled successfully but writing compiled file failed.", err
                        else
                          chownr {username, path: compiledFilePath}, callback
                  else
                    callback null

  publishApp:(options, callback)->

    {username, profile, version, appName, userAppPath} = options

    if username not in dummyAdmins
      callback? new AuthorizationError username
      return no

    # Put a check from api if user has the privilege

    appRootPath   = "/opt/Apps/#{username}/#{appName}"
    latestPath    = nodePath.join appRootPath, "latest"
    versionedPath = nodePath.join appRootPath, version
    userAppPath   = escapePath userAppPath

    log.info appRootPath, latestPath, versionedPath, userAppPath

    cb = (err)->
      console.error err if err
      callback? err, null

    fs.exists versionedPath, (exists)->
      if exists then cb "[ERROR] Version is already published, change version and try again!"
      else
        mkdirp appRootPath, (err)->
          if err then cb err
          else
            fse.copyRecursive userAppPath, versionedPath, (err)->
              if err then cb err
              else
                manifestPath = nodePath.join versionedPath, ".manifest"
                exec "cat '#{manifestPath}'", (err, stdout, stderr)->
                  if err or stderr then cb err
                  else
                    exec "rm -f #{manifestPath}", ->
                      manifest = JSON.parse stdout
                      manifest.author = "#{profile.firstName} #{profile.lastName}"
                      manifest.authorNick = username
                      delete manifest.devMode if manifest.devMode
                      unescapedManifestPath = "/opt/Apps/#{username}/#{appName}/#{version}/.manifest"
                      fs.writeFile unescapedManifestPath, JSON.stringify(manifest, null, 2), 'utf8', cb

  approveApp: (options, callback)->

    {username, authorNick, version, appName} = options

    if username not in dummyAdmins
      callback? new AuthorizationError username
      return no

    appRootPath   = escapePath "/opt/Apps/#{authorNick}/#{appName}"
    latestPath    = escapePath "/opt/Apps/#{authorNick}/#{appName}/latest"
    versionedPath = escapePath "/opt/Apps/#{authorNick}/#{appName}/#{version}"

    cb = (err)->
      console.error err if err
      callback? err, null

    exec "test -d #{versionedPath}", (err, stdout, stderr)->
      if err or stderr.length
        cb "[ERROR] Version is not exists!", version
      else
        exec "rm -f #{latestPath} && ln -s #{versionedPath} #{latestPath}", (err, stdout, stderr)->
          if err or stderr then cb err
          else cb null
