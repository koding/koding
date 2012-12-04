# mount remote filesystem kites

config = require './config'

path   = require "path"
fs     = require "fs"
log4js = require 'log4js'
log    = log4js.getLogger("[#{config.name}]")
{exec} = require "child_process"



mounter =

  remountVE: (options, callback)->

    # remount user's ve

    # options =
    #   username : String # koding username

    {username} = options

    exec "#{config.cagefsctl} -m #{username}",(err, stdout, stderr)->
      if err
        log.error error = "[ERROR] Couldn't remount user's VE - username #{username}: #{stderr}"
        callback error
      else
        log.info info = "[OK] user's VE #{username} remounted"
        callback null, info


   createMountpoint : (options, callback)->

     # create mount point for remote resource
     # /Users/<username>/RemoteDrive/<remote_hostname>

     # options =
     #  mountpoint : String # mountpoint for remount drive

     {mountpoint} = options

     fs.stat mountpoint, (err,stats)->
       if stats
         log.info info = "[OK] #{mountpoint} already exists"
         callback null, info
       else
         fs.mkdir mountpoint, 0755,(err)->
           if err?
             log.error error = "[ERROR] Couldn't create mountpoint #{mountpoint}: #{err.message}"
             callback error
           else
             log.info info = "[OK] mountpoint #{mountpoint} created"
             callback null, info

    mountFtpDrive : (options, callback)->

      # mount FTP to the users home directory

      # options =
      #   username : String # koding username
      #   remoteuser  : String # FTP username
      #   remotepass  : String # FTP password
      #   remotehost  : String # FTP server address
      #
      {username, remoteuser, remotepass, remotehost} = options

      options.mountpoint = path.join config.usersPath, username, config.baseMountDir, remotehost
      ftpfsopts = "#{config.ftpfs.opts},uid=`/usr/bin/id -u #{username}`,gid=`/usr/bin/id -g #{username}`,fsname=#{remotehost},user=#{remoteuser}:#{remotepass}"

      @createMountpoint options,(err,res)=>
        if err
          callback err
        else
          exec "#{config.ftpfs.curlftpfs} -o #{ftpfsopts} #{remotehost} #{options.mountpoint}", (err, stdout, stderr)=>
            if err?
              log.error error = "[ERROR] couldn't mount remote FTP server #{remotehost}: #{stderr}"
              callback error
            else
              @remountVE options, (err,res)->
                if err
                  callback err
                else
                  callback null,res

    mountSshDrive : (options, callback)->

      # mount SSHfs to the user's home directory

      # options =
      #   username : String # koding username
      #   remoteuser : String # SSH username
      #   remotepass : String # SSH password
      #   remotehost : String # SSH server address
      #   sshkey     : Bool # auth with key true/false

      {username, remoteuser, remotepass, remotehost, sshkey} = options

      options.mountpoint =  path.join config.usersPath, username, config.baseMountDir, remotehost

      if sshkey?
        sshopts = "#{config.sshfs.optsWithKey},fsname=#{remotehost}"
        sshcmd  = "#{config.sshfs.sshfscmd} -o #{sshopts} #{remoteuser}@#{remotehost}:/ #{options.mountpoint}"
      else
        sshopts = "#{config.sshfs.opts},fsname=#{remotehost}"
        sshcmd  = "/bin/echo '#{remotepass}' | #{config.sshfs.sshfscmd} -o #{sshopts} #{remoteuser}@#{remotehost}:/ #{options.mountpoint}"

      @createMountpoint options, (err, res)=>
        if err
          callback err
        else
          exec "/bin/echo '#{remotepass}' | #{config.sshfs.sshfscmd} -o #{sshopts} #{remoteuser}@#{remotehost}:/ #{options.mountpoint}", (err, stdout, stderr)=>
            if err?
              log.error error = "[ERROR] couldn't mount remote FTP server #{remotehost}: #{stderr}"
              callback error
            else
              @remountVE options, (err,res)->
                if err
                  callback err
                else
                  callback null, res

    umountDrive : (options, callback)->

      # umount FTP from user's home directory

      # options =
      #   username : String # koding username
      #   remotehost  : String # FTP server address

      {username, remotehost} = options

      options.mountpoint = path.join config.usersPath, username, config.baseMountDir, remotehost

      exec "/bin/umount #{options.mountpoint}",(err, stdout, stderr)=>
        if err
          log.error error = "[ERROR] can't umount #{options.mountpoint}: #{stderr}"
          callback error
        else
          log.info info = "[OK] directory #{options.mountpoint} umounted"
          @remountVE options,(err,res)->
            if err
              callback err
            else
              callback null,res


#options =
#  username: "aleksey-m"
#  remoteuser: "aleksey-m"
#  remotepass: "xxxx"
#  remotehost: "ftp.beta.koding.com"
#
#mounter.mountFtpDrive options,(err,res)->
#  console.log err,res
