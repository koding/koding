log4js    = require 'log4js'
log       = log4js.getLogger('[SharedHostingApi]')

fs = require 'fs'
hat = require 'hat'
{exec} = require 'child_process'

config = require './config'

# HELPERS
createTmpDir = require './createtmpdir'

createTmpFile =(username, command, callback)->
  tmpFile = "/Users/#{username}/.tmp/tmp_#{hat()}.sh"
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

execute = (options,callback)->

  {filename,command,username} = options
  if filename
    execStr = "chown #{username} #{filename} && su -l #{username} -c 'sh #{filename}'"
    unlink = yes
  else if command
    execStr = "su -l #{username} -c '#{command}'"
    unlink = no
  else
    log.error "execute can only work with provided .filename or .command"

  cmd = exec execStr, {maxBuffer: 1024*1024}, (err,stdout,stderr)->
    respond {err,stdout,stderr},callback
    fs.unlink filename if unlink is yes
    log.debug "executed", truncateOutput execStr


truncateOutput = (output)->

  if output.length > 300
    "#{output[0...300]} ...[truncated output]"
  else
    output

respond = (options,callback)->

  if Array.isArray options
    [err,stdout,stderr] = options
  else
    {err,stdout,stderr} = options

  if err?
    callback stderr,stdout
    if stdout
      log.warn "[WARNING]", err, truncateOutput(stderr), truncateOutput stdout
    else
      log.error "[ERROR]", err, truncateOutput stderr
  else
    # log.info "[OK] command \"#{command}\" executed for user #{username}"
    callback? null,stdout

containsAnyChar =(haystack, needle)->
  # for char in needle
  #   if ~haystack.indexOf char
  #     return yes
  # no
  a = createRegExp needle
  return a.test haystack


createRegExp = do ->
  memos = {}
  (str, flags)->
    return memos[str] if memos[str]?
    special = /(\.|\^|\$|\*|\+|\?|\(|\)|\[|\{|\\|\|)/
    memos[str] = RegExp '('+str.split('').map(
      (char)-> char.replace special, (_, foundChar)-> '\\'+foundChar
    ).join('|')+')', flags


module.exports =(options, callback)->
  #
  # this method will execute any system command inside user's env
  #
  # options =
  #   username : String #username of the unix user
  #   command  : String #bash command
  #
  # START
  # if command.contains anyOf ";&|><*?`$(){}[]!#'"
    # 1- create tmpdir /Users/[username]/.tmp
    # 2- create tmpfile /Users/[username]/.tmp/tmp_[uniqid].txt
    # 3- write the command inside the tmp file
    # 4- bash execute the tmp file with su -l [username]
    # 5- delete the tmpfile.
  # else
  #   1- execute command with su -l username -c 'command'

  {username,command} = options

  # log.debug "func:executeCommand: executing command #{command}"
  @checkUid options, (error)->
    if error?
      callback? error
    else
      chars = ";&|><*?`$(){}[]!#"
      if containsAnyChar command,chars
        log.debug "exec in a file",command
        prepareForBashExecute options, (err, filename)->
          unless err
            execute {filename,username},callback
          else
            callback err
            log.error err
      else
        execute {command,username},callback
        # log.debug "exec directly",command
