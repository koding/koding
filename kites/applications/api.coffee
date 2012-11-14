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
executeCommand = require '../sharedHosting/executecommand'

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
dummyAdmins = ["devrim", "sinan", "chris", "aleksey", "gokmen", "arvid"]

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
    kpmAppPath  = escapePath "/opt/Apps/#{owner}/#{appName}/#{version}"
    userAppPath = escapePath appPath

    if kpmAppPath.indexOf("/opt/Apps/") isnt 0 or not safeForUser username, userAppPath
      callback? new AuthorizationError username
      return false

    fs.exists kpmAppPath, (exists)->
      if not exists then callback? new KodingError "App files not found! Install cancelled."
      else
        executeCommand {username, command: "mkdir -p #{userAppPath}"}, (err)->
          if err then new KodingError "Cannot create Application directory", userAppPath
          else
            fse.copy "#{kpmAppPath}/index.js", "#{userAppPath}/index.js", (err)->
              fse.copy "#{kpmAppPath}/.manifest", "#{userAppPath}/.manifest", (err)->
                chownr {username, path: userAppPath}, callback
  copyAppSkeleton:(options, callback)->
    {username, appPath, type} = options

    appPath = normalizeUserPath(username, escapePath "#{appPath}/")
    type = "blank" if not type in ["blank", "sample"]

    if safeForUser username, appPath
      getIds options.username, (err, {uid, gid})->
        if err
          console.error err
          callback err
        else
          fse.copy "/opt/Apps/.defaults/#{type}/README", "#{appPath}/README", (err)->
            fse.copy "/opt/Apps/.defaults/#{type}/index.coffee", "#{appPath}/index.coffee", (err)->
              fse.copyRecursive "/opt/Apps/.defaults/#{type}/resources", "#{appPath}/resources", (err)->
                if err
                  console.error err
                  callback err
                else
                  chownr
                    path : "#{appPath}/"
                    uid  : uid
                    gid  : gid
                  , (err)->
                    console.error err if err
                    callback err
    else
      callback new AuthorizationError username

  publishApp:(options, callback)->

    {username, profile, version, appName, userAppPath} = options

    if username not in dummyAdmins
      callback? new AuthorizationError username
      return no

    # Put a check from api if user has the privilege

    appRootPath   = escapePath "/opt/Apps/#{username}/#{appName}"
    latestPath    = escapePath "/opt/Apps/#{username}/#{appName}/latest"
    versionedPath = escapePath "/opt/Apps/#{username}/#{appName}/#{version}"
    userAppPath   = escapePath userAppPath

    cb = (err)->
      console.error err if err
      callback? err, null

    createAppsDir username, (err)->
      makedirp appRootPath, username, (err)->
        if err then cb err
        else
          exec "test -d #{versionedPath}", (err, stdout, stderr)->
            unless err or stderr.length then cb "[ERROR] Version is already published, change version and try again!"
            else
              exec "cp -r #{userAppPath} #{versionedPath}", (err, stdout, stderr)->
                if err or stderr then cb err
                else
                  manifestPath = "#{versionedPath}/.manifest"
                  exec "cat #{manifestPath}", (err, stdout, stderr)->
                    if err or stderr then cb err
                    else
                      exec "rm -f #{manifestPath}", ->
                        manifest = JSON.parse stdout
                        manifest.author = "#{profile.firstName} #{profile.lastName}"
                        manifest.authorNick = username
                        delete manifest.devMode if manifest.devMode
                        unescapedManifestPath = "/opt/Apps/#{username}/#{appName}/#{version}/.manifest"
                        fs.writeFile unescapedManifestPath, JSON.stringify(manifest, null, 2), 'utf8', cb

  downloadApp: (options, callback)->

    {username, owner, appName, version, appPath} = options

    cb = (err)->
      console.error err if err
      callback? err, null

    version   or= 'latest'
    kpmAppPath  = escapePath "/opt/Apps/#{owner}/#{appName}/#{version}"
    userAppPath = escapePath appPath
    backupPath  = "#{appPath}.org.#{(Date.now()+'').substr(-4)}"

    if kpmAppPath.indexOf("/opt/Apps/") isnt 0 or not safeForUser username, userAppPath
      callback? new AuthorizationError username
      return false

    exec "test -d #{kpmAppPath}", (err, stdout, stderr)->
      if err or stderr.length
        cb "[ERROR] App files not found! Download cancelled."
      else
        exec "mv #{userAppPath} #{backupPath} && cp -r #{kpmAppPath}/ #{userAppPath} && chown -R #{username}: #{userAppPath}", (err, stdout, stderr)->
          if err or stderr then cb err
          else
            cb null

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
