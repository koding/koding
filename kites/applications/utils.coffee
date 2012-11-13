
# Custom Libraries for this Util
fs        = require 'fs'
mkdirp    = require 'mkdirp'
{walk}    = require 'walk'
coffee    = require 'coffee-script'
nodePath  = require 'path'
{exec}    = require 'child_process'

# Custom Auth Error
class AuthorizationError extends Error
  constructor:(username, message)->
    console.error "[AuthorizationError] User '#{username}' made something bad."
    return new AuthorizationError(message) unless @ instanceof AuthorizationError
    Error.call @
    @message = message or "You are not authorized to do this."
    @name = 'AuthorizationError'

normalizeUserPath = (username, path)-> path?.replace(/\~/g, '/Users/#{username}')
safeForUser       = (username, path)-> path?.indexOf("/Users/#{username}/") is 0
escapePath        = (path)-> if path then nodePath.normalize path.replace(/[^a-zA-Z0-9\/\-. ]/g, '')
                                                                 .replace(/\s/g, '\\ ')

makedirp = (path, username, callback)->
  mkdirp path, (err)->
    # It will just apply the chown for the latest dir
    # Needs to FIX
    chownr {path, username}, callback

createAppsDir = (user, cb)->
  path = escapePath "/Users/#{user}/Applications"
  if not safeForUser user, path
    cb new AuthorizationError user
  else
    makedirp path, user, cb

chownr = (options, callback)->
  {path, username, uid, gid} = options

  letsWalk = (uid, gid)->
    fs.chown path, uid, gid, (err)->
      walker = walk path
      for type in ["file", "directory"]
        walker.on type, (root, stat, next)->
          filePath = nodePath.join root, stat.name
          fs.chown filePath, uid, gid, (err)->
            next() if not err
      walker.on "end", callback

  if not uid or not gid
    getIds username, (err, {uid, gid})->
      if not err then letsWalk uid, gid
      else callback err
  else
    letsWalk uid, gid

getIds = (username, callback)->
  exec "/usr/bin/id #{username}", (err, stdout, stderr)->
    callback err if err
    [tmp, uid, gid] = stdout.match /^[^\d]+(\d+)[^\d]+(\d+)/
    callback null, {uid:+uid, gid:+gid}

# Export them'all
module.exports.normalizeUserPath  = normalizeUserPath
module.exports.safeForUser        = safeForUser
module.exports.escapePath         = escapePath
module.exports.createAppsDir      = createAppsDir
module.exports.chownr             = chownr
module.exports.getIds             = getIds
module.exports.makedirp           = makedirp
module.exports.AuthorizationError = AuthorizationError