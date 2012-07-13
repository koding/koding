log4js = require 'log4js'
log    = log4js.getLogger('[SharedHostingApi]')
fs     = require 'fs'
{exec} = require 'child_process'
path   = require 'path'
#config = require('./config').FileSharing
config = 
  baseSharedDir : '/Shared'
  baseDir : '/Users'
  setfacl : '/usr/bin/setfacl'

class FileSharing

  execSetAcl : (username, sharedDir, action) ->
    if action == 'set'
      setfacl   = "#{config.setfacl} -m d:u:#{username}:rwx #{sharedDir} && #{config.setfacl} -m u:#{username}:rwx #{sharedDir}"
    else if action == 'remove'
      setfacl   = "#{config.setfacl} -x d:u:#{username} #{sharedDir} && #{config.setfacl} -R -x u:#{username} #{sharedDir}"
    else
      log.error "Unknown action '#{action}'"
      return false
    
    exec setfacl, (err,stdout,stderr) ->
      if err?
        log.error err = "[ERROR] Can't execute #{setfacl}: #{stderr}"
        return false
      else
        log.info "[OK] acl on #{sharedDir} changed with #{setfacl}"
        return true


  linkToHome : (owner, username, callback) ->
    sharedDir = path.join config.baseSharedDir, owner
    symlink   = path.join config.baseDir, username, "Shared", owner
    link  = "/bin/ln -Ts #{sharedDir} #{symlink}"
    exec link, (err, stdout, stderr) ->
      if err?
        log.error err = "[ERROR] Can't link #{sharedDir} to #{symlink}"
        callback err
      else
        log.info "[OK] shared dir #{sharedDir} linked to #{symlink}"
        callback null


  setOwnerAcl : (owner, callback) ->
    if not owner?
      log.error err = "[ERROR] username should be defined"
      callback err
    else
      sharedDir = path.join config.baseSharedDir, owner
      if not @execSetAcl(owner, sharedDir, 'set')
        callback "[ERROR] can't share dir #{sharedDir}"
      else
        callback null

  createSharedDir : (owner, callback) ->
    sharedDir = path.join config.baseSharedDir, owner
    fs.mkdir sharedDir, 0720, (err, stat) =>
      if err?
        log.error err
        callback err
      else
        @setOwnerAcl owner,(err)=>
          if err?
            callback err
          else
            @linkToHome owner, owner, (err) ->
              if err?
                log.error err = "[ERROR] Couldnt create shared dir for #{owner}"
                callback err
              else
                log.info "[OK] shared dir #{sharedDir} for user #{owner} successfully created"
                callback null
    
  shareWithUser : (owner, username, callback)->
    
    sharedDir = path.join config.baseSharedDir, owner
    if not @execSetAcl(username, sharedDir, 'set')
      callback "[ERROR] can't share dir #{sharedDir} for user #{username}"
    else
       @linkToHome owner, username, (err) ->
         if err?
           log.error err = "[ERROR] Couldnt share  dir #{sharedDir} with #{username}"
           callback err
         else
           log.info "[OK] dir #{sharedDir} successfully shared with #{username}"
           callback null

  unshareWithUser : (owner, username, callback) ->

    sharedDir = path.join config.baseSharedDir, owner
    symlink   = path.join config.baseDir, username, "Shared", owner
    if not @execSetAcl(username, sharedDir, 'remove')
      callback "[ERROR] can't unshare dir #{sharedDir} for user #{username}"
    else
       fs.unlink symlink, (err)->
         if err?
           log.error err = "[ERROR] Couldnt unshare #{owner}'s  dir for #{username}: #{err.message}"
           callback err
         else
           log.info "[OK] dir #{sharedDir} successfully unshared for #{username}"
           callback null


fileSharing = new FileSharing
module.exports = fileSharing

#fileSharing.unshareWithUser 'alekseymykhailov', 'devrim', (err)->
#  if err?
#    log.error err

#fileSharing.createSharedDir 'alekseymykhailov',(err)->
#  if err?
#    log.error err
#
#fileSharing.createSharedDir "alekseymykhailov", (err)->
#  if err?
#    log.error err

#fileSharing.shareWithUser "alekseymykhailov", "devrim",(err)->
#  if err?
#    log.error err
