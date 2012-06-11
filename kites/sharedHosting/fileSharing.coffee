log4js = require 'log4js'
log    = log4js.getLogger('[SharedHostingApi]')
fs     = require 'fs'
{exec} = require 'child_process'
path   = require 'path'


config = 
  baseSharedDir : '/Shared'
  setfacl : '/usr/bin/setfacl'


execFacl = (username, sharedDir) ->
  setfacl   = "#{config.setfacl} -m d:u:#{username}:rwx #{sharedDir} && #{config.setfacl} -m u:#{username}:rwx #{sharedDir}"
  exec setfacl, (err,stdout,stderr) ->
    if err?
      log.error err = "[ERROR] Can't execute #{setfacl}: #{stderr}"
      return false
    else
      log.info "[OK] acl on #{sharedDir} changed with #{setfacl}"
      return true




setOwnerAcl = (username, callback) ->
  if not username?
    log.error err = "[ERROR] username should be defined"
    callback err
  else
    sharedDir = path.join config.baseSharedDir, username
    if not execFacl(username, sharedDir)
      callback "[ERROR] can't share dir #{sharedDir}"

createSharedDir = (username, callback) ->
  sharedDir = path.join config.baseSharedDir, username
  fs.mkdir sharedDir, 0720, (err, stat) ->
    if err?
      log.error err
      callback err
    else
      setOwnerAcl username,(err)->
        if err?
          callback err
        else
          log.info "[OK] shared dir #{sharedDir} for user #{username} successfully created "
          callback null
  
shareWithUser = (owner, user, callback)->
  
  sharedDir = path.join config.baseSharedDir, owner
  setfacl   = "#{config.setfacl} -m d:u:#{user}:rwx #{sharedDir} && #{config.setfacl} -R -m u:#{user}:rwx #{sharedDir}"

  exec setfacl, (err, stdout, stderr) ->
    if err?
      log.error err = "[ERROR] Can't execute #{setfacl}: #{stderr}"
      callback err
    else
      log.info "[OK] acl on #{sharedDir} changed with #{setfacl}"
      callback null




