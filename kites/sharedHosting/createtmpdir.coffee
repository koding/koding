fs = require 'fs'

log4js    = require 'log4js'
log       = log4js.getLogger('[SharedHostingApi]')

config = require './config'

module.exports = createTmpDir =(username, callback=->)->
  tmpDir = "#{config.usersPath}#{username}/.tmp"
  fs.stat tmpDir, (err, stat)->
    console.log "Creating:::", tmpDir, err, stat
    if err
      fs.mkdir tmpDir, 0o0755, (err)->
        if err
          callback err
          log.error err
        else
          # log.debug ".tmp dir is there"
          callback null, tmpDir
    else
      if stat.isDirectory()
        # log.debug ".tmp dir is there"
        callback null, tmpDir
      else
        log.error ".tmp file is found where we need .tmp directory. deleting.."
        fs.unlink tmpDir, (err)->
          unless err
            createTmpDir username, callback
          else
            log.debug ".tmp file is found where we need .tmp directory. file deleted, .tmp dir is created."
            callback null, tmpDir
