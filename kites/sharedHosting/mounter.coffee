# mount remote filesystem kites

config = require './config'

path   = require "path"
fs     = require "fs"
_      = require "underscore"
log4js = require 'log4js'
log    = log4js.getLogger("[#{config.name}]")
{exec} = require "child_process"
{spawn}   = require "child_process"



mounter = 
  
  # this module provides functions for mount remote FTP and SSH servers with fuse-curlftpfs and fuse-sshfs
  
  # usage:
  #
  # MOUNT methods
  #    options =
  #      type: <sting> # this value doesn't require for mounting. It is only for config files (can be "ssh" or "ftp")
  #      username: <string> # Koding account name
  #      remoteuser: <string> # user on ftp or ssh server
  #      remotepass: <sting> # plain text password for ftp/ssh user. Note: for ssh it can be ommited if ssh key exists, use sshkey: <bool> for this
  #      remotehost: <string> # remote SSH/FTP hostname (FQDN) 
  #      sshkey: <bool> # set true for ssh mounts if ssh key exists
  #
  #   mountFtpDrive options,(err,res)->
  #   mountSshDrive options,(err,res)->
  #   

  # UMOUNT methods
  #   options =
  #      username: <string> # Koding account name
  #      remotehost: <string> # remote SSH/FTP hostname (FQDN) 
  #
  #   umountDrive options,(err,res)->

  # read all mounts related to user
  #   options =
  #      username: <string> # Koding account name
  #
  #   readMountInfo options,(err,res)->
     
  
  readMountInfo: (options, callback)->
     # this method will return user's mounts from mount config /Users/<username>/.mounts
     
     # return 
     #   callback error 
     #   callback null, array of objects
     
     # options = 
     #   username : String # koding username
     
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


  updateMountCfg : (options, callback)->
     
     # this method update user's mount config file  /Users/<username>/.mounts


     # return 
     #   callback error 
     #   callback null, result (information message)

     # options = 
     #   username : String # koding username
     #   type : String # type of mount (ftp,ssh)
     #   remoteuser : String # FTP username
     #   remotehost : String # FTP server address
     #   mountpoint : String # mountpoint for remount drive
     
     {username, type, remoteuser, remotehost, mountpoint} = options
     
     newConf = 
       type: type
       remotehost: remotehost
       remoteuser: remoteuser
       mountpoint: mountpoint

     cfg = path.join config.usersPath, username, config.usersMountsFile

     fs.stat cfg ,(err,stats)=>
       if stats
         @readMountInfo options, (err, res)->
           if err?
             callback err
           else
             trigger = 0
             for obj in res
               if _.isEqual obj,newConf
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


  cleanMountConf: (options, callback)->
    
    # this method will remove mount config related to remote host from user's mount config

     # return 
     #   callback error 
     #   callback null, result (information message)


    # options =
    #   remotehost : String # remote server address
    #   username : String # koding username

    {remotehost,username} = options

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

  spawnWrapper = (command, args , callback)->
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
    spawnWrapper config.cagefsctl, args ,(err, res)->
      if err?
        log.error error = "[ERROR] Couldn't remount user's VE - username #{username}: #{stderr}"
        callback error
      else
        log.info info = "[OK] user's VE #{username} remounted"
        callback null, info


   createMountpoint = (options, callback)->
   
     # create mount point for remote resource
     # /Users/<username>/RemoteDrive/<remote_hostname>
 
     # return 
     #   callback error 
     #   callback null, result (information message)

     
     # options =
     #  mountpoint : String # mountpoint for remount drive

     {mountpoint} = options
     
     fs.stat mountpoint, (err,stats)->
       if stats
         log.info info = "[OK] #{mountpoint} already exists"
         callback null, info
       else
         fs.mkdir mountpoint, '0755',(err)->
           if err?
             log.error error = "[ERROR] Couldn't create mountpoint #{mountpoint}: #{err.message}"
             callback error
           else
             log.info info = "[OK] mountpoint #{mountpoint} created"
             callback null, info

    mountFtpDrive : (options, callback)->

      # mount FTP to the users home directory

      # return 
      #   callback error 
      #   callback null, result (information message)


      # options = 
      #   username : String # koding username
      #   type: Sting # this value doesn't require for mounting. It is only for config files (can be "ssh" or "ftp")
      #   remoteuser  : String # FTP username
      #   remotepass  : String # FTP password
      #   remotehost  : String # FTP server address
      #
      {username, remoteuser, remotepass, remotehost} = options
      
      options.mountpoint = path.join config.usersPath, username, config.baseMountDir, remotehost
      
      # fetch user ID for curlftfs command
      spawnWrapper '/usr/bin/id', ['-u',username], (err,res)=>
        if err?
          log.error error = "[ERROR] Can't find user ID: #{err}"
          callback error
        else
          log.info "[OK] user ID for user #{username} is #{res}"
          ftpfsopts = "#{config.ftpfs.opts},uid=#{res},gid=#{res},fsname=#{remotehost},user=#{remoteuser}:#{remotepass}"
          createMountpoint options,(err,res)=>
            if err
              callback err
            else
              spawnWrapper config.ftpfs.curlftpfs,['-o', ftpfsopts, remotehost, options.mountpoint] , (err, res)=>
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
               

    mountSshDriveWithKey: (options, callback)->
      # mount SSHfs to the user's home directory
   
      # return 
      #   callback error 
      #   callback null, result (information message)

   
      # options =
      #   username : String # koding username
      #   type : String # type of mount (ftp,ssh)
      #   remoteuser : String # SSH username
      #   remotepass : String # SSH password
      #   remotehost : String # SSH server address
      #   sshkey     : Bool # auth with key true/false

      {username, remoteuser, remotepass, remotehost, sshkey} = options

      options.mountpoint =  path.join config.usersPath, username, config.baseMountDir, remotehost
      keyPath = path.join config.usersPath,username,'.ssh','koding.pem'
      sshopts = [ "-d", "-o", "#{config.sshfs.optsWithKey},fsname=#{remotehost} -i #{keyPath}", "#{remoteuser}@#{remotehost}:/", options.mountpoint]
      console.log sshopts  
      createMountpoint options, (err, res)=>
        if err
          callback err
        else
          spawnWrapper config.sshfs.sshfscmd, sshopts, (err, res)=>
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
      #   type : String # type of mount (ftp,ssh)
      #   remoteuser : String # SSH username
      #   remotepass : String # SSH password
      #   remotehost : String # SSH server address
      #   sshkey     : Bool # auth with key true/false

      {username, remoteuser, remotepass, remotehost, sshkey} = options

      options.mountpoint =  path.join config.usersPath, username, config.baseMountDir, remotehost
      
      sshopts = [ "-o", "#{config.sshfs.opts},fsname=#{remotehost}", "#{remoteuser}@#{remotehost}:/", options.mountpoint]
      console.log sshopts  
      createMountpoint options, (err, res)=>
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
      #   type : String # type of mount (ftp,ssh)
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



    umountDrive : (options, callback)->
      
      # umount FTP from user's home directory

      # return 
      #   callback error 
      #   callback null, result (information message)


      # options =
      #   username : String # koding username
      #   remotehost  : String # FTP server address

      {username, remotehost} = options

      options.mountpoint = path.join config.usersPath, username, config.baseMountDir, remotehost

      spawnWrapper '/bin/umount', [options.mountpoint],(err, res)=>
        if err?
          log.error error = "[ERROR] can't umount #{options.mountpoint}: #{stderr}"
          callback error
        else
          log.info info = "[OK] directory #{options.mountpoint} umounted"
          @remountVE options,(err,res)=>
            if err
              callback err
            else
              @cleanMountConf options,(err,res)->
              callback null,res


module.exports = mounter

