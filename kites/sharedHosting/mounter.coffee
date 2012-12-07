# mount remote filesystem kites

config   = require './config'

path     = require "path"
fs       = require "fs"
mkdirp   = require 'mkdirp'
_        = require "underscore"
log4js   = require 'log4js'
log      = log4js.getLogger("[#{config.name}]")
{exec}   = require "child_process"
{spawn}  = require "child_process"

# Utilities
{normalizeUserPath,
 safeForUser,
 escapePath,
 makedirp,
 slugify,
 chownr,
 getIds,
 KodingError,
 AuthorizationError} = require '../applications/utils.coffee'

mounter =

  mountDrive : (options, callback)->

    # mount already registered FTP/SSH remote to the users home directory

    # options
    #   remotetype : String # If its not provided we will try to guess from config
    #   remotehost : String # remote FTP/SFTP hostname
    #   remotepass : String # plain text password for ftp/ssh user.
    #   storepass  : Bool   # store password in config, default false

    # return
    #   callback error
    #   callback null, result (information message)

    {username, remotehost, remotepass, remotetype} = options

    @readMountInfo options, (err,res)=>
      if err?
        callback err
      else
        mounts = [mount for mount in res when mount.remotehost is remotehost][0]

        if mounts.length is 0 or res.length is 0
          callback "No such remote registered with '#{remotehost}' name."
          return no

        if mounts.length > 1 and remotetype
          mounts = [mount for mount in mounts when mount.remotetype is remotetype][0]
          if mounts.length > 1
            callback "Duplicate entries for same remote, ask Koding admins for help."
            return no

        mount = mounts[0]

        mount.username  = options.username
        mount.storepass = options.storepass

        switch mount.remotetype
          when "ftp"
            console.log "Calling....."
            @mountFtpDrive mount, callback

  # Safe
  mountFtpDrive : (options, callback)->

    # mount FTP to the users home directory

    # options
    #   remoteuser : String # user on ftp server
    #   remotepass : String # plain text password for ftp user.
    #   remotehost : String # remote FTP hostname (FQDN)
    #   storepass  : Bool   # store password in config, default false

    # return
    #   callback error
    #   callback null, result (information message)

    options.remoteuser or= 'anonymous'
    options.remotepass or= 'anonymous'
    options.storepass    = yes if options.remotepass is 'anonymous'
    options.remotetype   = 'ftp'

    {username, remoteuser, remotepass, remotehost, storepass} = options

    unless remotehost
      callback "Remote host is not provided"
      return no

    options.mountpoint = escapePath path.join config.usersPath, username, config.baseMountDir, remotehost

    unless safeForUser username, options.mountpoint
      console.error "User [#{username}] is trying to make something bad: ", options.mountpoint
      callback "You are not authorized to do this."
      return no

    # fetch user ID for curlftfs command
    @spawnWrapper '/usr/bin/id', ['-u', username], (err,res)=>
      if err?
        log.error error = "[ERROR] Can't find user ID: #{err}"
        callback error
      else
        uid = res.trim()
        log.info "[OK] user ID for user #{username} is #{uid}"
        ftpfsopts = "#{config.ftpfs.opts},uid=#{uid},gid=#{uid},fsname=#{remotehost}"
        @createMountpoint options, (err,res)=>
          if err
            callback err
          else
            options.install = true
            @tmpNetrc options,(err,res)=>
              if err?
                callback err
              else
                HOME = process.env.HOME
                process.env.HOME = path.join config.usersPath, username
                console.log "tmp home for .netrc is #{process.env.HOME}"
                @spawnWrapper config.ftpfs.curlftpfs,['-o', ftpfsopts, remotehost, options.mountpoint] , (err, res)=>
                  process.env.HOME = HOME
                  console.log "home changed back to #{process.env.HOME}"
                  options.install = false
                  @tmpNetrc options,(err,res)=>
                  if err?
                    log.error error = "[ERROR] couldn't mount remote FTP server #{remotehost}: #{err}"
                    callback error
                  else
                    @remountVE options, (err,res)=>
                      if err?
                        callback err
                      else
                        @updateMountCfg options,(err,res)->
                        callback null,res

  tmpNetrc : (options,callback)->

    # this method will create .netrc file for curlftpfs

    {username, remotehost, remoteuser, remotepass, install} = options
    rcPath = escapePath path.join config.usersPath, username, '.netrc'

    unless safeForUser username, rcPath
      console.error "User [#{username}] is trying to make something bad: ", cfg
      callback "You are not authorized to do this."
      return no

    if install
      conf = "machine #{remotehost} login #{remoteuser} password #{remotepass}"
      fs.writeFile rcPath, conf, 'utf-8', (err)->
        if err?
          console.error error = "[error] couldn't write .netrc file #{rcPath}: #{err.message}"
          callback error
        else
          console.log info = "[ok] .netc #{rcPath} installed"
          callback null, info
    else
      fs.unlink rcPath, (err)->
        if err?
          console.err error = "[ERROR] couldn't remove .netrc file #{rcPath}: #{err.message}"
          callback error
        else
          console.log info = "[OK] .netrc file #{rcPath} has been removed"
          callback null, info

  # Safe
  umountDrive : (options, callback)->

    # umount FTP from user's home directory

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #   username   : String # koding username
    #   remotehost : String # FTP server address

    {username, remotehost} = options

    unless remotehost
      callback "Remote host is not given"
      return no

    options.mountpoint = escapePath path.join config.usersPath, username, config.baseMountDir, remotehost

    unless safeForUser username, options.mountpoint
      console.error "User [#{username}] is trying to make something bad: ", options.mountpoint
      callback "You are not authorized to do this."
      return no

    @spawnWrapper '/bin/umount', [options.mountpoint],(err, res)=>
      if err?
        log.error error = "[ERROR] can't umount #{options.mountpoint}: #{err}"
        callback error
      else
        log.info info = "[OK] directory #{options.mountpoint} umounted"
        @remountVE options,(err,res)=>
          if err
            callback err
          else
            fs.rmdir options.mountpoint, (err)->
              # not a big issue
              if err?
                console.warn "Couldn't remove mountpoint #{options.mountpoint}: #{err.message}"
              else
                console.log "mountpoint #{options.mountpoint} has been removed"
              callback null

  # Safe
  readMountInfo: (options, callback)->

    # Return user's mounts from mount config /Users/<username>/.mounts

    # return
    #   callback error
    #   callback null, array of objects

    # options =
    #   username : String # Koding account name

    {username} = options

    cfg = path.join config.usersPath, username, config.usersMountsFile

    fs.readFile cfg,(err,data)->
      if err?
        log.error error = "[ERROR] Couldn't read config file #{cfg}: #{err.message}"
        callback error
      else
        try
          currentConf = JSON.parse data
          log.info "[OK] config #{cfg} successfully parsed"
          callback null, currentConf
        catch error
          log.error error = "[ERROR] Couldn't parse config #{cfg}: #{error}"
          callback error

  # Safe
  updateMountCfg : (options, callback)->

    # this method update user's mount config file  /Users/<username>/.mounts

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #   username : String # koding username
    #   remotetype : String # remotetype of mount (ftp,ssh)
    #   remoteuser : String # FTP username
    #   remotehost : String # FTP server address
    #   mountpoint : String # mountpoint for remount drive
    #   storepass  : Bool   # store password in config, default false

    {username, remotetype, remoteuser, remotehost, mountpoint, storepass} = options

    newConf = {remotetype, remotehost, remoteuser, mountpoint}

    if storepass
      newConf.remotepass = options.remotepass

    cfg = escapePath path.join config.usersPath, username, config.usersMountsFile

    unless safeForUser username, cfg
      console.error "User [#{username}] is trying to make something bad: ", cfg
      callback "You are not authorized to do this."
      return no

    console.log newConf

    fs.stat cfg, (err,stats)=>
      if stats
        @readMountInfo options, (err, res)->
          if err?
            callback err
          else
            trigger = 0
            for obj in res
              if _.isEqual obj, newConf
                trigger += 1
                break
            if trigger is 0
              res.push newConf
              jsonConf = JSON.stringify res
              fs.writeFile cfg, jsonConf, 'utf-8',(err)->
                if err?
                  log.error error = "[error] couldn't update config #{cfg}: #{err.message}"
                  callback error
                else
                  log.info info = "[ok] config successfully updated"
                  callback null, info
            else
              log.warn warn = "[WARN] config for #{remotehost} already exists"
              callback null, warn
      else
        jsonConf = JSON.stringify [newConf]
        fs.writeFile cfg, jsonConf, 'utf-8',(err)->
          if err?
            log.error error = "[error] couldn't update config #{cfg}: #{err.message}"
            callback error
          else
            fs.chmod cfg,'0600',(err)->
            log.info info = "[ok] config successfully created"
            callback null, info

  removeMount: (options, callback)->

    # this method will remove mount config related to remote host from user's mount config

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #   remotehost : String # remote server address
    #   username   : String # koding username

    {remotehost, username} = options

    cfg = path.join config.usersPath, username, config.usersMountsFile

    @readMountInfo options, (err,res)->
      if err?
        callback err
      else
        index = 0
        for elem in res
          if elem.remotehost is not remotehost
            index+=1
          else
            res.splice(index,1)
            break
        jsonConf = JSON.stringify res
        fs.writeFile cfg, jsonConf, 'utf-8',(err)->
          if err?
            log.error error = "[ERROR] Couldn't update config #{cfg}: #{err.message}"
            callback error
          else
            log.info info = "[OK] config successfully updated"
            callback null, info


  mountSshDriveWithKey: (options, callback)->
    # mount SSHfs to the user's home directory

    # return
    #   callback error
    #   callback null, result (information message)


    # options =
    #   username : String # koding username
    #   remotetype : String # remotetype of mount (ftp,ssh)
    #   remoteuser : String # SSH username
    #   remotepass : String # SSH password
    #   remotehost : String # SSH server address
    #   sshkey     : Bool # auth with key true/false

    {username, remoteuser, remotepass, remotehost, sshkey} = options

    options.mountpoint =  path.join config.usersPath, username, config.baseMountDir, remotehost
    keyPath = path.join config.usersPath,username,'.ssh','koding.pem'
    sshopts = [ "-o", "ssh_command=/usr/bin/ssh -i #{keyPath} -o #{config.sshfs.optsWithKey},fsname=#{remotehost}", "#{remoteuser}@#{remotehost}:/", options.mountpoint]
    console.log sshopts
    @createMountpoint options, (err, res)=>
      if err
        callback err
      else
        @spawnWrapper config.sshfs.sshfscmd, sshopts, (err, res)=>
          if err?
            log.error error = "[ERROR] couldn't mount remote SSH server #{remotehost}: #{err}"
            callback error
          else
            @remountVE options, (err,res)=>
              if err
                callback err
              else
                @updateMountCfg options,(err,res)->
                callback null, res

  mountSshDriveWithPass : (options, callback)->

    # mount SSHfs to the user's home directory

    # return
    #   callback error
    #   callback null, result (information message)


    # options =
    #   username : String # koding username
    #   remotetype : String # remotetype of mount (ftp,ssh)
    #   remoteuser : String # SSH username
    #   remotepass : String # SSH password
    #   remotehost : String # SSH server address
    #   sshkey     : Bool # auth with key true/false

    {username, remoteuser, remotepass, remotehost, sshkey} = options

    options.mountpoint =  path.join config.usersPath, username, config.baseMountDir, remotehost

    sshopts = [ "-o", "ssh_command=/usr/bin/ssh -o #{config.sshfs.opts},fsname=#{remotehost}", "#{remoteuser}@#{remotehost}:/", options.mountpoint]
    console.log sshopts
    @createMountpoint options, (err, res)=>
      if err
        callback err
      else
        pw  = spawn '/bin/echo', [remotepass]
        ssh = spawn config.sshfs.sshfscmd, sshopts

        pw.stdout.on "data", (data) ->
          ssh.stdin.write data

        pw.stderr.on "data", (data) ->
          pwerror = "pw stderr: #{data}"

        pw.on "exit", (code) ->
          if code isnt 0
            log.error pwcb = "[ERROR] pw process exited with code #{code}, #{pwerror}"
            callback pwcb

        ssh.stdout.on "data", (data) ->
          log.info data

        ssherror = ''
        ssh.stderr.on "data", (data) ->
          ssherror += "ssh stderr: #{data}"

        ssh.on "exit", (code) =>
          if code isnt 0
            log.error  "[ERROR] ssh process exited with code #{code}: #{ssherror}"
            callback "[ERROR] couldn't mount ssh fs"
          else
            @remountVE options, (err,res)=>
              if err
                callback err
              else
                @updateMountCfg options,(err,res)->
                callback null, res

  mountSshDrive: (options, callback)->

    # mount SSHfs to the user's home directory

    # return
    #   callback error
    #   callback null, result (information message)


    # options =
    #   username : String # koding username
    #   remotetype : String # remotetype of mount (ftp,ssh)
    #   remoteuser : String # SSH username
    #   remotepass : String # SSH password
    #   remotehost : String # SSH server address
    #   sshkey     : Bool # auth with key true/false

    {sshkey} = options

    if sshkey?
      @mountSshDriveWithKey options,(err,res)->
        callback err if err?
        callback null, res if res?
    else
      @mountSshDriveWithPass options,(err,res)->
        callback err if err?
        callback null, res if res?

  # Safe
  remountVE: (options, callback)->

    # remount user's ve
    # if remote drive umounted from main system , user's "container" should be reloaded to umount drive from it

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #   username : String # koding username

    {username} = options
    args = ['-m', username]
    @spawnWrapper config.cagefsctl, args ,(err, res)->
      if err?
        log.error error = "[ERROR] Couldn't remount user's VE - username #{username}: #{stderr}"
        callback error
      else
        log.info info = "[OK] user's VE #{username} remounted"
        callback null, info

  spawnWrapper : (command, args , callback)->
    wrapper = spawn command,args
    wrapperErr = ""
    wrapper.stderr.on 'data',(data)->
      wrapperErr += data
    wrapperData = ""
    wrapper.stdout.on 'data',(data)->
      wrapperData += data

    wrapper.on 'exit',(code)->
      if code isnt 0
        log.error err = "[ERROR] command error: #{wrapperErr}"
        callback err
      else
        log.info res = wrapperData.toString("utf-8", 0, 12)
        log.info info = "[OK] command executed successfully output: #{res}"
        callback null, res

  # Safe
  createMountpoint : (options, callback)->

    # create mount point for remote resource
    # /Users/<username>/RemoteDrive/<remote_hostname>

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #  mountpoint : String # mountpoint for remount drive

    {mountpoint, username} = options

    unless mountpoint
      callback "Mountpoint is not provided"
      return no

    unless safeForUser username, mountpoint
      console.error "User [#{username}] is trying to make something bad: ", mountpoint
      callback "You are not authorized to do this."
      return no

    fs.stat mountpoint, (err,stats)->
      if stats
        log.info info = "[OK] #{mountpoint} already exists"
        callback null, info
      else
        mkdirp mountpoint, 0o0755, (err)->
          if err?
            log.error error = "[ERROR] Couldn't create mountpoint #{mountpoint}: #{err.message}"
            callback error
          else
            chownr {username, path:mountpoint}, (err)->
              unless err
                log.info info = "[OK] mountpoint #{mountpoint} created"
                callback null, info
              else
                log.error "An error occured:", err
                callback err


module.exports = mounter
