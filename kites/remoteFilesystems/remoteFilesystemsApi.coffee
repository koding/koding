log4js = require 'log4js'
log    = log4js.getLogger('[remoteFilesystemsApi]')
fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'


config =
  usersPath         : '/Users/'
  remoteDriveDir    : 'RemoteDrives'

class RemoteFs


  createMountPoint = (options,callback)->

    #
    # create mountpoint for remote drive
    #

    #
    # options =
    #   username     : String # OS username
    #   mountPoint   : String # local mount point
    #
    {username,mountPoint} = options

    fullMountPointPath = path.join config.usersPath,username,config.remoteDriveDir,mountPoint

    log.debug "[OK] creating mountpoint #{fullMountPointPath}"
    fs.stat fullMountPointPath,(err,stats)->
      if err?
        fs.mkdir fullMountPointPath,0755,(err)->
          if err?
            log.error "[ERROR] can't create mountpoint #{fullMountPointPath} for remote drive (user #{username}): #{err.message}"
            callback "[ERROR] can't create  mountpoint #{fullMountPointPath} for remote drive (user #{username}): #{err.message}"
          else
            log.debug "[OK] mount point #{fullMountPointPath} created for user #{username}"
            callback null, "[OK] mount point #{fullMountPointPath} created for user #{username}"
      else
        log.debug "[OK] directory #{fullMountPointPath} already exitst"
        callback null,"[OK] directory #{fullMountPointPath} already exitst"

  executeSshFs = (options,callback)->

    #
    # execute sshfs command
    #

    #
    # options =
    #   username     : String # OS username
    #   mountPoint   : String # local mount point
    #   remoteServer : String # remote server address
    #   remoteUser   : String # remote server user
    #   remoteDir    : String # directory on the remote server
    #   remotePass   : String # remote user password
    #   remotePort   : Number # remote server port (optional) - default 22
    #

    {username,mountPoint,remoteServer,remoteUser,remoteDir,remotePass,remotePort,privateKey} = options

    remoteMountPointBaseDir = path.join config.usersPath,username,config.remoteDriveDir
    mountPoint = path.join remoteMountPointBaseDir,mountPoint


    mountOpts = "password_stdin,intr,allow_other"
    if remotePort? then mountOpts = mountOpts+",port=#{remotePort}"
    log.debug "echo xxxxxx | /usr/bin/sshfs -d -o #{mountOpts} #{remoteUser}@#{remoteServer}:#{remoteDir}  #{mountPoint}"
    mountssh = exec "echo #{remotePass} | /usr/bin/sshfs  -o #{mountOpts} \
                                                    #{remoteUser}@#{remoteServer}:#{remoteDir} \
                                                    #{mountPoint}", (err,stdout,stderr)->
      # TODO: error handling
      if err?
        # parsing error
        # ssh errors 3th string
        mounterr = stderr.split('\n')[2]
        if not mounterr?
          # so it can be fuse error
          mounterr = stderr.split(':')
          mounterr = "#{mounterr[1]}:#{mounterr[2]}"
          if not mounterr?
            mounterr = "Unknown error"
        log.debug "[ERROR] unknown mount error is #{stderr}"
        log.error "[ERROR] can't mount remote ssh drive : #{mounterr}"
        callback "[ERROR] can't mount remote ssh drive : #{mounterr}"
      else
        log.info "[OK] #{remoteServer}:#{remoteDir} mounted for user #{username}"
        callback null, "[OK] #{remoteServer}:#{remoteDir} mounted for user #{username}"

  mountSshFS : (options,callback)->

    #
    # this method will mount remount resource with fuse-sshfs
    #

    #
    # options =
    #   username     : String # OS username
    #   mountPoint   : String # local mount point
    #   remoteServer : String # remote server address
    #   remoteUser   : String # remote server user
    #   remoteDir    : String # directory on the remote server
    #   remotePass   : String # remote user password
    #   remotePort   : Number # remote server port (optional) - default 22
    #

    {username,mountPoint,remoteServer,remoteUser,remoteDir,remotePass,remotePort,privateKey} = options

    remoteMountPointBaseDir = path.join config.usersPath,username,config.remoteDriveDir
    fullMountPointPath      = path.join remoteMountPointBaseDir,mountPoint
    log.debug remoteMountPointBaseDir
    # check if remote mount base dir exitsts

    fs.stat remoteMountPointBaseDir,(err,stats)->
      if err?
        log.debug "[WARN] #{remoteMountPointBaseDir} doesnt exists -> creating"
        fs.mkdir remoteMountPointBaseDir,0755,(err)->
          if err?
            log.error "[ERROR] can't create basedir #{remoteMountPointBaseDir} for remote drive (user #{username}): #{err.message}"
            callback "[ERROR] can't create basedir #{remoteMountPointBaseDir} for remote drive (user #{username}): #{err.message}"
          else
            createMountPoint options,(error,result)->
              if error?
                callback error
              else
                executeSshFs options,(error,result)->
                  if error?
                    callback error
                  else
                    callback null,result
      else # base dir exists
        log.debug "[OK] base dir #{remoteMountPointBaseDir} exists "

        createMountPoint options,(error,result)->
          if error?
            callback error
          else
            executeSshFs options,(error,result)->
              if error?
                callback error
              else
                callback null,result




mountRemote = new RemoteFs

module.exports = mountRemote