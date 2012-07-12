log4js    = require 'log4js'
log       = log4js.getLogger('[SharedHostingApi]')

fs = require 'fs'
hat = require 'hat'
{exec} = require 'child_process'

# HELPERS
createTmpDir =(username, callback)->
  tmpDir = "/Users/#{username}/.tmp"
  fs.stat tmpDir, (err, stat)->
    if err
      fs.mkdir tmpDir, 0755, (err)->
        if err
          callback? err
          log.error err
        else
          log.debug ".tmp dir is there"
          callback? null
    else
      if stat.isDirectory()
        log.debug ".tmp dir is there"
        callback? null
      else
        log.error ".tmp file is found where we need .tmp directory. deleting.."
        fs.unlink tmpDir, (err)->
          unless err
            createTmpDir username, callback
          else
            log.debug ".tmp file is found where we need .tmp directory. file deleted, .tmp dir is created."
            callback? null

createTmpFile =(username, command, callback)->
  tmpFile = "/Users/#{username}/.tmp/tmp_#{hat()}.sh"
  log.debug command
  fs.writeFile tmpFile,command,'utf-8',(err)->
    if err
      callback? err
    else
      callback? null,tmpFile

prepareForBashExecute =(options, callback)->
  {username,command} = options
  createTmpDir username, (err)->
    if err
      log.error err
      callback err
    else
      log.debug "[OK] executing command for #{username}: #{command}"
      createTmpFile username, command, (err, tmpfile)->
        if err then callback? err
        else callback null, tmpfile

module.exports =(options, callback)->
  #
  # this method will execute any system command inside user's env
  #
  # options =
  #   username : String #username of the unix user
  #   command  : String #bash command
  #
  # START
  # 1- create tmpdir /Users/[username]/.tmp
  # 2- create tmpfile /Users/[username]/.tmp/tmp_[uniqid].txt
  # 3- write the command inside the tmp file
  # 4- bash execute the tmp file with su -l [username]
  # 5- delete the tmpfile.

  {username,command} = options

  log.debug "func:executeCommand: executing command #{command}"
  @checkUid options, (error)->
    if error?
      callback? error
    else
      prepareForBashExecute options, (err, tmpFile)->
        log.info tmpFile
        unless err
          cmd = exec "chown #{username} #{tmpFile};su -l #{username} -c 'sh #{tmpFile}'",(err,stdout,stderr)->
            if err?
              log.error "[ERROR] can't execute command \"#{command}\" for user #{username}: #{stderr}"
              callback? stderr,stdout
            else
              log.info "[OK] command \"#{command}\" executed for user #{username}"
              callback? null,stdout
            fs.unlink tmpFile
        else
          log.error err
          callback err
