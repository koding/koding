
# Config
config    = require './config'

# Logger
log4js    = require 'log4js'
log       = log4js.getLogger("[#{config.name}]")

# Custom Libraries for this Util
fs        = require 'fs'
mkdirp    = require 'mkdirp'
{walk}    = require 'walk'
coffee    = require 'coffee-script'
nodePath  = require 'path'
{exec}    = require 'child_process'

crypto    = require 'crypto'

# Custom Auth Error
class AuthorizationError extends Error
  constructor:(username, message)->
    console.error "[AuthorizationError] User '#{username}' made something bad."
    return new AuthorizationError(message) unless @ instanceof AuthorizationError
    Error.call @
    @message = message or "You are not authorized to do this."
    @name = 'AuthorizationError'

# General Purpose Error
class KodingError extends Error
  constructor:(message, details)->
    log.error message, details
    return new KodingError(message) unless @ instanceof KodingError
    Error.call @
    @message = message
    @details = details if details
    @name = 'KodingError'

normalizeUserPath = (username, path)-> path?.replace(/\~/g, "/Users/#{username}")
safeForUser       = (username, path)-> path?.indexOf("/Users/#{username}/") is 0
escapePath        = (path, keepSpaces = no)->
  if path
    path = nodePath.normalize path.replace(/[^a-zA-Z0-9\/\-. ]/g, '')
    if keepSpaces then return path
    path.replace(/\\/g, '')
        .replace(/\s/g, '\\ ')

makedirp = (path, username, callback)->
  mkdirp path, (err)->
    # It will just apply the chown for the latest dir
    # Needs to FIX
    chownr {path, username}, callback

createAppsDir = (username, cb)->
  path = escapePath "/Users/#{username}/Applications"
  if not safeForUser username, path
    cb new AuthorizationError username
  else
    makedirp path, username, cb

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

slugify = (title = "")->
  url = title
    .toLowerCase()                # change everything to lowercase
    .replace(/^\s+|\s+$/g, "")    # trim leading and trailing spaces
    .replace(/[_|\s]+/g, "-")     # change all spaces and underscores to a hyphen
    .replace(/[^a-z0-9-]+/g, "")  # remove all non-alphanumeric characters except the hyphen
    .replace(/[-]+/g, "-")        # replace multiple instances of the hyphen with a single instance
    .replace(/^-+|-+$/g, "")      # trim leading and trailing hyphens

# Encrypt / Decrypt usage taken from http://stackoverflow.com/a/10550004/1370271

encrypt = (input, password) ->

  md5 = crypto.createHash("md5")
  md5.update password

  key = md5.digest("hex")
  md5 = crypto.createHash("md5")
  md5.update password + key

  iv = md5.digest("hex")

  data      = new Buffer(input, "utf8").toString("binary")
  cipher    = crypto.createCipheriv("aes-256-cbc", key, iv.slice(0, 16))
  encrypted = cipher.update(data, "binary") + cipher.final("binary")

  new Buffer(encrypted, "binary").toString("base64")

decrypt = (input, password) ->

  # Convert urlsafe base64 to normal base64
  input = input.replace(/\-/g, "+").replace(/_/g, "/")

  # Convert from base64 to binary string
  edata = new Buffer(input, "base64").toString("binary")

  # Create key from password
  md5 = crypto.createHash("md5")
  md5.update password
  key = md5.digest("hex")

  # Create iv from password and key
  md5 = crypto.createHash("md5")
  md5.update password + key
  iv = md5.digest("hex")

  # Decipher encrypted data
  decipher = crypto.createDecipheriv("aes-256-cbc", key, iv.slice(0, 16))
  decrypted = decipher.update(edata, "binary") + decipher.final("binary")
  new Buffer(decrypted, "binary").toString("utf8")

# console.log "Encrypting..."
# console.log "Encoded:", encoded = encrypt("gokmen", "askldfhlaksd")
# console.log "Decoded:", decrypt(encoded, "askldfhlaksd")

# Export them'all
exports.normalizeUserPath  = normalizeUserPath
exports.safeForUser        = safeForUser
exports.escapePath         = escapePath
exports.createAppsDir      = createAppsDir
exports.chownr             = chownr
exports.getIds             = getIds
exports.makedirp           = makedirp
exports.slugify            = slugify
exports.encrypt            = encrypt
exports.decrypt            = decrypt

# Errors
exports.KodingError        = KodingError
exports.AuthorizationError = AuthorizationError