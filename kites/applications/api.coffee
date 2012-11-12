
# Kite requirements
Kite         = require 'kite-amqp'
config       = require './config'

# Logger
log4js       = require 'log4js'
log          = log4js.getLogger("[#{config.name}]")

# Custom Libraries for this Kite
{exec}       = require 'child_process'
fs           = require 'fs'
mkdirp       = require 'mkdirp'
createTmpDir = require './createtmpdir'

# Utilities
{normalizeUserPath,
 safeForUser,
 escapePath,
 createAppsDir,
 chownr,
 getIds,
 AuthorizationError} = require './utils.coffee'

# Dummy-Admins
dummyAdmins = ["devrim", "sinan", "chris", "aleksey", "gokmen", "arvid"]

module.exports = new Kite 'applications'

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

  installApp: (options, callback)->

    {username, owner, appPath, appName, version} = options
    version ?= 'latest'

    cb = (err)->
      console.error err if err
      callback? err, null

    kpmAppPath = escapePath "/opt/Apps/#{owner}/#{appName}/#{version}"
    appPath    = escapePath appPath

    if kpmAppPath.indexOf("/opt/Apps/") isnt 0 or not safeForUser username, appPath
      callback? new AuthorizationError username
      return false

    createAppsDir username, (err)->
      makedirp appPath, username, (err)->
        if err then cb err
        else
          exec "cp #{kpmAppPath}/index.js #{appPath} && cp #{kpmAppPath}/.manifest #{appPath}", (err, stdout, stderr)->
            if err or stderr.length
              cb err or "[ERROR] #{stderr}"
            else
              exec "chown -R #{username}: #{appPath}", (err, stdout, stderr)->
                if err or stderr.length
                  cb err or "[ERROR] #{stderr}"
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

