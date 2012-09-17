# mount remote filesystem kites

config = require './config'

path   = require "path"
log4js = require 'log4js'
log    = log4js.getLogger("[#{config.name}]")
{exec} = require "child_process"



mounter = 
  
  remountVE: (options, callback)->

    # remount user's ve 

    # options =
    #   username : String # koding username

    exec "#{config.cagefsctl} -m #{username}",(err, stderr, stdout)->
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
      #   ftpuser  : String # FTP username
      #   ftppass  : String # FTP password
      #   ftphost  : String # FTP server address
      #
      {username, ftpuser, ftppass, ftphost} = options
      
      options.mountpoint = path.join config.usersPath, username, config.baseMountDir
      ftpfsopts = "#{config.ftpfs.opts},uid=`/usr/bin/id -u #{username}`,gid=`/usr/bin/id -g #{username},fsname=#{ftphost},user=#{ftpuser}:#{ftppass}"
      
      @createMountpoint options,(err,res)=>
        if err
          callback err
        else
          exec "#{config.curlftpfs} #{ftpfsopts} #{ftphost} #{options.mountpoint}", (err, stderr, stdout)=>
            if err?
              log.error error = "[ERROR] couldn't mount remote FTP server #{ftphost}: #{stderr}"
              callback error
            else
              @remountVE options, (err,res)->
                if err
                  callback err
                else
                  callback null,res

