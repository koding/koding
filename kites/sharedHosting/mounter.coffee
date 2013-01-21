
config  = require './config'
path    = require "path"
fs      = require "fs"
mkdirp  = require 'mkdirp'
log4js  = require 'log4js'
log     = log4js.getLogger("[#{config.name}]")

{exec}  = require 'child_process'
{spawn} = require "child_process"

# Utilities
{normalizeUserPath,
 safeForUser,
 escapePath,
 makedirp,
 slugify,
 chownr,
 encrypt,
 decrypt,
 getIds,
 KodingError,
 AuthorizationError} = require '../applications/utils.coffee'

# Dummy-Admins
# dummyAdmins = ["devrim", "sinan", "chris", "aleksey", "gokmen", "arvidkahl"]

startsWith = (str, part)-> str.trim().indexOf(part) is 0
endsWith   = (str, part)-> str.trim().indexOf(part, str.trim().length - part?.length) isnt -1

mounter    =

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

    {username, remotehost, remotepass, remotetype, remoteuser, storepass} = options

    @readMountInfo options, (err,res)=>
      if err?
        callback err
      else
        mounts = [mount for mount in res when (mount.remotehost is remotehost and mount.remoteuser is remoteuser)][0]

        if mounts.length is 0 or res.length is 0
          callback "No such remote registered with '#{remotehost}' name."
          return no

        if mounts.length > 1 and remotetype
          mounts = [mount for mount in mounts when mount.remotetype is remotetype][0]
          if mounts.length > 1
            callback "Duplicate entries for same remote, ask Koding admins for help."
            return no

        mount = mounts[0]

        mount.username   = username
        mount.storepass  = storepass
        mount.mountonly  = yes

        if mount.remotepass?
          mount.remotepass = decrypt mount.remotepass, "#{config.encryptKey}==#{username}"
        else
          mount.remotepass = remotepass if remotepass

        switch mount.remotetype
          when "ftp"
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
    options.storepass  or= yes if options.remotepass is 'anonymous'
    options.remotetype   = 'ftp'

    {username, remoteuser, remotepass, remotehost, storepass, mountonly} = options

    unless remotehost
      callback "Remote host is not provided"
      return no

    options.mountpoint = escapePath path.join config.usersPath, username, config.baseMountDir, remoteuser
    options.mountpoint+= "@#{escapePath remotehost}"

    unless safeForUser username, options.mountpoint
      console.error "User [#{username}] is trying to make something bad: ", options.mountpoint
      callback "You are not authorized to do this."
      return no

    @getRemotesCount options, (count)=>
      if count >= config.maxAllowedRemotes
        callback "You've reached your limits for remote drives. Please remove one of remotes to add new one."
        return no

      # fetch user ID for curlftfs command
      getIds username, (err, ids)=>
        if err
          log.error error = "[ERROR] Can't find user ID: #{err}"
          callback error
        else
          @checkMountPoint options, (err, state)=>
            if state.mounted
              callback "Remote host is already mounted to #{state.mountpoint}"
            else
              {uid} = ids
              log.info "[OK] user ID for user #{username} is #{uid}"
              ftpfsopts = "#{config.ftpfs.opts},uid=#{uid},gid=#{uid},fsname=#{remotehost},user=#{remoteuser}:#{remotepass}"
              @createMountpoint options, (err)=>
                if err
                  callback err
                else
                  @spawnWrapper config.ftpfs.curlftpfs, ['-o', ftpfsopts, remotehost, options.mountpoint], (err)=>
                    if err
                      log.error error = "Couldn't mount remote FTP server #{remotehost}: #{err}"
                      fs.rmdir options.mountpoint, (err)->
                        log.error err if err
                        callback error
                    else
                      @remountVE options, (err)=>
                        if err
                          callback err
                        else
                          @updateMountCfg options, (err, res)->
                            callback null, res

  # Safe
  checkMountPoint : (options, callback)->
    #
    # this method checks if remount host mounted (it doesn't check for availability)
    #
    #

    #
    # return =
    #   mounted: Bool # true/false
    #   remotehost: String # remote FTP/SFTP hostname
    #   remoteuser: String # remote FTP/SFTP username
    #   mountpoint: Strint # full path to the mountpoint

    {username, remoteuser, remotehost, mountpoint} = options

    options.mountpoint = escapePath path.join config.usersPath, username, config.baseMountDir, remoteuser
    options.mountpoint+= "@#{escapePath remotehost}"

    unless safeForUser username, options.mountpoint
      console.error "User [#{username}] is trying to make something bad: ", options.mountpoint
      callback "You are not authorized to do this."
      return no

    fc  = ''
    res = {mounted : false, remotehost, mountpoint : options.mountpoint}

    rs = fs.createReadStream '/proc/mounts', flags: 'r'
    rs.setEncoding()

    rs.on 'error', (err)->
      console.error error = "Unexpected error : couldn't retrieve mount info: #{err.message}"
      callback error

    rs.on 'data', (data)->
      fc += data

    rs.on 'end', ->
      mounts = [mount.split(' ', 2) for mount in fc.split('\n') when startsWith mount, remotehost][0]
      if mounts.length > 0
        state = [line for line in mounts when (startsWith(line[1], "/Users/#{username}/") and \
                                               endsWith(  line[1], "#{remoteuser}@#{remotehost}"))][0]
        if state.length > 0
          [remote, mountpoint] = state[0]
          console.log "[OK] #{remotehost} is mounted for user #{username} to #{mountpoint}"
          res = {mounted: true, remotehost, mountpoint}

      rs.destroy()

      callback null, res

  # Safe
  umountDrive : (options, callback)->

    # umount FTP from user's home directory

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #   username   : String # koding username
    #   remoteuser : String # FTP username
    #   remotehost : String # FTP server address

    {username, remotehost, remoteuser, mountpoint} = options

    if not remotehost or not remoteuser
      callback "Remote host/user is not given"
      return no

    unless mountpoint
      options.mountpoint = escapePath path.join config.usersPath, username, config.baseMountDir, remoteuser
      options.mountpoint+= "@#{escapePath remotehost}"

    unless safeForUser username, options.mountpoint
      console.error "User [#{username}] is trying to make something bad: ", options.mountpoint
      callback "You are not authorized to do this."
      return no

    @checkMountPoint options, (err, state)=>
      if not state.mounted
        callback "Its already unmounted."
      else
        # This is too dangerous
        @spawnWrapper '/sbin/fuser', ['-mk', options.mountpoint], (err, res)=>
          @spawnWrapper '/bin/umount', [options.mountpoint], (err, res)=>
            if err?
              log.error error = "Can't umount #{options.mountpoint}: #{err}"
              callback error
            else
              log.info info = "Directory #{options.mountpoint} umounted"
              @remountVE options, (err,res)=>
                if err
                  callback err
                else
                  fs.rmdir options.mountpoint, (err)->
                    # not a big issue
                    if err?
                      console.warn "Couldn't remove mountpoint #{options.mountpoint}: #{err.message}"
                    else
                      console.log "mountpoint #{options.mountpoint} has been removed"
                    callback null, info

  # Safe
  readMountInfo:(options, callback)->

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
        callback null, []
      else
        try
          currentConf = JSON.parse data
          log.info "[OK] config #{cfg} successfully parsed"
          callback null, currentConf
        catch error
          log.error error = "[ERROR] Couldn't parse config #{cfg}: #{error}"
          callback error

  # Safe
  getRemotesCount:(options, callback)->
    @readMountInfo options, (err, content)->
      unless err
        callback content.length
      else
        callback 0

  # Safe
  updateMountCfg:(options, callback)->

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
      newConf.remotepass = encrypt options.remotepass, "#{config.encryptKey}==#{username}"

    cfg = escapePath path.join config.usersPath, username, config.usersMountsFile

    unless safeForUser username, cfg
      console.error "User [#{username}] is trying to make something bad: ", cfg
      callback "You are not authorized to do this."
      return no

    fs.stat cfg, (err, stats)=>
      if stats
        @readMountInfo options, (err, res)->
          if err?
            callback err
          else
            filteredMounts = [mount for mount in res when (mount.remotehost is options.remotehost and mount.remoteuser is options.remoteuser)][0]
            if filteredMounts.length is 0
              res.push newConf
              jsonConf = JSON.stringify res
              fs.writeFile cfg, jsonConf, 'utf-8',(err)->
                if err?
                  log.error error = "Couldn't update config #{cfg}: #{err.message}"
                  callback error
                else
                  log.info info = "Config successfully updated"
                  callback null, info
            else
              log.warn warn = "Config for #{remotehost} already exists"
              callback null, warn
      else
        jsonConf = JSON.stringify [newConf]
        fs.writeFile cfg, jsonConf, 'utf-8',(err)->
          if err?
            log.error error = "Couldn't update config #{cfg}: #{err.message}"
            callback error
          else
            fs.chmod cfg,'0600',(err)->
            log.info info = "Config successfully created"
            callback null, info

  # Safe
  removeMount: (options, callback)->

    # this method will remove mount config related to remote host from user's mount config

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #   remotehost : String # remote server address
    #   username   : String # koding username

    {username, mountpoint} = options

    cfg = path.join config.usersPath, username, config.usersMountsFile

    @readMountInfo options, (err,res)->
      if err?
        callback err
      else
        filteredMounts = [mount for mount in res when mount.mountpoint isnt mountpoint][0]
        jsonConf = JSON.stringify filteredMounts or ''
        fs.writeFile cfg, jsonConf, 'utf-8',(err)->
          if err?
            log.error error = "Couldn't update config #{cfg}: #{err.message}"
            callback error
          else
            log.info info = "Config successfully updated"
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

    options.mountpoint =  path.join config.usersPath, username, config.baseMountDir, remoteuser
    options.mountpoint+= "@#{escapePath remotehost}"

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

    options.mountpoint =  path.join config.usersPath, username, config.baseMountDir, remoteuser
    options.mountpoint+= "@#{escapePath remotehost}"

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
        log.error error = "Couldn't remount user's VE - username #{username}: #{err}"
        callback error
      else
        log.info info = "User: #{username} virtual environment remounted."
        callback null, info

  spawnWrapper : (command, args, callback)->
    wrapper = spawn command, args

    wrapperErr = ""
    wrapper.stderr.on 'data',(data)->
      wrapperErr += data

    wrapperData = ""
    wrapper.stdout.on 'data',(data)->
      wrapperData += data

    wrapper.on 'exit',(code)->
      if code isnt 0
        log.error err = "Command #{command} error: (code: #{code}) #{wrapperErr}" if wrapperErr
        callback wrapperErr.toString("utf-8", 0, 12) or yes
      else
        res = wrapperData.toString("utf-8", 0, 12)
        log.info info = "Command #{command} executed successfully output: #{res}" if res
        callback null, res

  # Safe
  createMountpoint : (options, callback)->

    # create mount point for remote resource
    # /Users/<username>/RemoteDrives/<remote_hostname>

    # return
    #   callback error
    #   callback null, result (information message)

    # options =
    #  mountpoint : String # mountpoint for remount drive

    {remoteuser, remotehost, username} = options

    mountpoint = escapePath path.join config.usersPath, username, config.baseMountDir, remoteuser
    mountpoint+= "@#{escapePath remotehost}"

    unless mountpoint
      callback "Mountpoint is not provided"
      return no

    unless safeForUser username, mountpoint
      console.error "User [#{username}] is trying to make something bad: ", mountpoint
      callback "You are not authorized to do this."
      return no

    fs.stat mountpoint, (err,stats)->
      if stats
        log.info info = "Mountpoint #{mountpoint} already exists"
        callback null, info
      else
        mkdirp mountpoint, 0o0755, (err)->
          if err?
            log.error error = "Couldn't create mountpoint #{mountpoint}: #{err.message}"
            callback error
          else
            chownr {username, path:mountpoint}, (err)->
              unless err
                log.info info = "Mountpoint #{mountpoint} created"
                callback null, info
              else
                log.error "An error occured:", err
                callback err

  clearLocks:(options, callback)->

    {username}  = options
    remotesPath = "/Users/#{username}/#{config.baseMountDir}"

    # console.log "CLEAR LOCKS CALLED FOR #{username}"

    cleanUpRemotesDir = (cb)=>
      tmpBlackHole = "/Users/#{username}/.tmp/.BlackHole/.zz#{(Date.now()+'').substr(-6)}"

      # console.log "CLEANUP REMOTES DIR"
      # console.log remotesPath
      # console.log tmpBlackHole

      fs.exists remotesPath, (exists)=>
        # console.log "REMOTES DIR EXISTS?", exists
        unless exists then cb()
        else
          exec "/bin/rmdir #{remotesPath}/*", (err)=>
            unless err then cb()
            else
              mkdirp tmpBlackHole, 0o0755, (err)=>
                if err then cb()
                else
                  exec "/bin/mv #{remotesPath} #{tmpBlackHole}", (err)=>
                    console.log "RemoteDrive folder moved to BlackHole for #{username}"
                    cb()

    getIds username, (err, ids)=>
      if err or not ids
        # console.error err
        callback "Failed to authenticate."
      else
        # console.log "HAS ID #{ids.uid}"
        # Kill all process belongs to that user
        exec "/usr/bin/pgrep -U #{ids.uid}", (err)=>
          unless err
            exec "/usr/bin/pkill -9 -U #{ids.uid}", (err)->
              console.log "Process tree cleaned-up for #{username}" unless err
          # else
          #   console.log "NO SUCH PROCESS BELONGS TO USER #{username}"

        # FIXME This is just for curlftpfs
        # Kill all mount process points to user home
        args = "-u root -f '^/usr/bin/curlftpfs.* /Users/#{username}/'"
        exec "/usr/bin/pgrep #{args}", (err, res)=>
          unless err
            exec "/usr/bin/pkill #{args}", (err)=>
              # console.log "KILLING THEM ALL"
              console.log "Mount procceses killed for #{username}" unless err
              @remountVE {username}, =>
                cleanUpRemotesDir =>
                  mkdirp remotesPath, 0o0755, (err)->
                    callback "Process tree cleaned-up and RemoteDrives re-created."
              # callback()
          else
            cleanUpRemotesDir =>
              callback "Process tree cleaned-up."
            # callback()

module.exports = mounter

