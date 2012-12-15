config    = require './config'

log4js    = require 'log4js'
log       = log4js.getLogger("[#{config.name}]")

nodePath  = require 'path'
{exec}    = require 'child_process'
{spawn}   = require 'child_process'
fs        = require 'fs'
hat       = require 'hat'
ldap      = require 'ldapjs'
Kite      = require 'kite-amqp'
{bash}    = require 'koding-bash-user-glue'
mounter   = require './mounter'

createTmpDir = require './createtmpdir'

module.exports = new Kite 'sharedHosting'

  timeout:({timeout}, callback)->
    setTimeout (-> callback null, timeout), timeout

  interval:({interval}, callback)->
    setInterval (-> callback null, interval), interval

  executeCommand: require './executecommand'

  mountDrive    : (options, callback)-> mounter.mountDrive      options, callback
  umountDrive   : (options, callback)-> mounter.umountDrive     options, callback
  mountFtpDrive : (options, callback)-> mounter.mountFtpDrive   options, callback

  removeMount   : (options, callback)->
    mounter.umountDrive options, (error, res)->
      mounter.removeMount options, callback

  readMountInfo : (options, callback)->
    mounter.readMountInfo options, (err, res)->
      if err then callback err
      else
        # Check each entry's mount state and remove password
        updateEntries = (entries, index)=>
          if index == entries.length
            callback err, entries
          else
            entries[index].haspass = no
            if entries[index].remotepass
              entries[index].haspass = yes
            delete entries[index].remotepass
            mounter.checkMountPoint
              username   : options.username
              remoteuser : entries[index].remoteuser
              remotehost : entries[index].remotehost
            , (error, state)->
              unless error
                entries[index].mounted    = state.mounted
                entries[index].mountpoint = state.mountpoint if state.mounted
              updateEntries entries, index + 1

        updateEntries res, 0

  fetchSafeFileName:(options,callback)->
    {filePath}    = options
    original      = filePath+""
    originalDir   = nodePath.dirname original
    originalExt   = nodePath.extname original
    originalName  = nodePath.basename original,originalExt
    start = (i)->
      fs.stat filePath, (err,stat)->
        if stat?.isFile() or stat?.isDirectory()
          i++
          filePath = nodePath.join originalDir,originalName+"_"+i+originalExt
          start i
        else
          callback? null,filePath
    start 0

  uploadFile:(options,callback)->
    #
    # options =
    #    contents   : String # file text content
    #
    # console.log 'attempting to upload file', options
    {usersPath,fileUrl} = config
    {username,path,contents} = options
    log.debug "uploadFile is called",options.path
    createTmpDir username, (err, tmpDir)=>
      filename = hat()
      tmpPath = "#{tmpDir}/#{filename}"
      fs.writeFile tmpPath,contents,'utf8', (err)=>
        if err
          callback err
        else
          @executeCommand {username, command:"cp #{tmpPath} #{path}"}, (err,res)->
            unless err
              callback? null,path
            else
              callback? "[ERROR] can't upload file : #{err}"

  secureUser : (options,callback)->
    # put user to the secure env http://www.cloudlinux.com/docs/cagefs/

    # options =
    #   username : String #username of the unix user
    #
    {username} = options

    secureUser = exec "/usr/sbin/cagefsctl --enable #{username}", (err,stdout,stderr)->
      if err?
        log.error "[ERROR] can't put user #{username} to secure env: #{stderr}"
        callback? "[ERROR] can't put user #{username} to secure env: #{stderr}"
      else
        log.info "[OK] user #{username} was secured"
        callback? null,"[OK] user #{username} was secured"

  buildHome : (options,callback)->
    #
    # this methid will make home directory for user, set correct perms and copy all default files in it
    #

    # options =
    #   username: String #username of the unix user
    #   uid : Number # user's UID

    {username, uid} = options
    home = nodePath.join(config.usersPath,username)
    fs.mkdir home, 0o0755,(error)=>
      if error?
        log.error "[ERROR] can't make homedir for user #{username} in the #{config.usersPath}: #{error}"
      else
        # make default virtual host
        fs.chown home,uid,uid,(err)=>
          if err?
            log.error error = "[ERROR] can't change owner of home directory to UID/GID #{uid} for user #{username}: #{err}"
            callback error
          else
            @createVhost username:username,uid:uid,(err,res)->
              unless err
                log.info info = "[OK] default vhost and hosmedir for user #{username} is created"
                callback? null,info
              else
                log.error error = "[ERROR] couldn't create default vhost for #{username}: #{err}"
                callback? error

  createSystemUser : (options,callback)->
    #
    # This method will create operation system user with default group in LDAP
    # Note: you should not define default group for user. dafault group name has the same name with username
    #

    #
    # options =
    #   username : String #username of the unix user
    #   fullName : String #fullName - real name for unux user
    #   password : String #password of the unix

    #
    # return =
    #   backend : String # backend FQDN where user has created

    {username,fullName,password} = options

    # define user and group ldap schema

    user =
      objectClass: ['top','person','organizationalPerson','inetorgperson','posixAccount']
      cn : username
      loginShell: '/bin/bash'
      givenName: username
      sn : username
      uid: username
      gecos: fullName
      homeDirectory : '/Users/'+username
      userPassword: password

    group =
      objectClass: ['top','posixgroup','groupofuniquenames']
      cn: username

    # first of all we have to connect and bind to ldap
    ldapClient = ldap.createClient url:config.ldap.ldapUrl, maxConnections:1
    ldapClient.bind config.ldap.rootUser,config.ldap.rootPass,(err)=>
      if err?
        log.error error = "[ERROR] Can't bind to LDAP server #{config.ldap.ldapUrl}: #{err.message}"
        callback error
      else
        # search for  free UID
        ldapClient.search config.ldap.freeUID,attributes:'uidNumber',(err,res)=>
          callback err if err?
          res.on 'searchEntry', (entry)=>
            # increment current UID in the ldap database, we will use incremented for next new user
            id = entry.object.uidNumber
            user.uidNumber = user.gidNumber = group.gidNumber = id
            incrementedValue = parseInt(entry.object.uidNumber)+1
            change = new ldap.Change
              operation    :'replace'
              modification :
                uidNumber  : incrementedValue
               # now we can use free UID for our new user/group record
            #change_free_user_group = new ldap.Change
            #  operation     :'add'
            #  modification  :
            #    memberUid     : username

            ldapClient.add "uid=#{username},#{config.ldap.userDN}",user, (err)=>
              if err
                log.error error = "[ERROR] can't create ldap record for user #{username} in #{config.ldap.userDN} : #{err.message}"
                ldapClient.unbind (err)->
                  log.error err if err?
                callback error
              else
                log.info "[OK] User #{username} added to #{config.ldap.userDN}"
                # using username for groupname because it should be the same (same name and ID)
                ldapClient.add "cn=#{username},#{config.ldap.groupDN}",group,(err)=>
                  if err
                    log.error error =  "[ERROR] can't create ldap record for group #{username} in #{config.ldap.groupDN} : #{err.message}"
                    ldapClient.unbind (err)->
                      log.error err if err?
                    callback error
                  else
                    log.info "[OK] Group #{username} added to #{config.ldap.groupDN}"
                    ldapClient.modify config.ldap.freeUID,change,(err)=>
                      if err?
                        log.error error = "[ERROR] can't increment uidNumber for special record #{config.ldap.freeUID}: #{err.message}"
                        ldapClient.unbind (err)->
                          log.error err if err?
                        callback error
                      else
                        #ldapClient.modify config.ldap.freeGroup,change_free_user_group,(err)=>
                        #  if err?
                        #    log.error error = "[ERROR] can't add user to group #{config.ldap.freeGroup}: #{err.message}"
                        #    ldapClient.unbind (err)->
                        #      log.error err if err?
                        #    callback error
                        #  else
                        # now we can build home for user
                        ldapClient.unbind (err)->
                          log.error err if err?
                        @buildHome username:username,uid:parseInt(id), (error,result)->
                          if error?
                            callback error
                          else
                            callback null,"[OK] user and group #{username} has been added to LDAP"

  #createVhost : (options,callback)->

  #  {username,uid,domainName} = options

  #  domainName ?= "#{username}.#{config.defaultDomain}"
  #  targetPath = "/Users/#{username}/Sites/#{domainName}"

  #  userInputs = [targetPath, targetPath, uid, uid, targetPath, uid, uid]
  #  cmd        = "mkdir -p %s && cp -r #{config.defaultVhostFiles}/website %s && chown %s:%s -R %s/*"
  #  cmd       += " && echo 'curl https://koding.com/koding-announcement.txt' > /Users/#{username}/.bashrc && chown %s:%s /Users/#{username}/.bashrc"
  #  log.debug "executing CreateVhost:",cmd

  #  exec bash(cmd, userInputs), (err,stdout,stderr)->
  #    unless err
  #      callback null, "vhost created with default files:",domainName
  #    else
  #      log.error stderr
  #      callback stderr
  createVhost :do->

    spawnWrapper = (command, args , callback)->
      wrapper = spawn command,args
      wrapperErr = ""
      wrapper.stderr.on 'data',(data)->
        wrapperErr += data
      wrapperData = ""
      wrapper.stdout.on 'data',(data)->
        wrapperData += data
      wrapper.once 'error', (err)->
        callback err

      wrapper.on 'exit',(code)->
        if code is not 0
          log.error err = "execute command #{command} for createVhost: #{wrapperErr}"
          callback err
        else
          log.debug wrapperData.toString("utf-8", 0, 12)
          log.info info = "createVhost: #{command} done!"
          callback null, info

    createVhost = (options,callback)->
      {username,uid,domainName} = options

      domainName ?= "#{username}.#{config.defaultDomain}"
      targetPath = "/Users/#{username}/Sites/#{domainName}"

      createDirs = ['-v','-p',targetPath]
      copyFiles  = ['-v','-r',"#{config.defaultVhostFiles}/website",targetPath]
      changeOwner = ['-v','-R',"#{uid}:#{uid}","#{targetPath}/website"]

      spawnWrapper '/bin/mkdir',createDirs, (err,res)=>
        if err?
          callback "[ERROR] couldn't create vhost #{err}"
        else
          spawnWrapper '/bin/cp',copyFiles,(err,res)=>
            if err?
              callback "[ERROR] couldn't create vhost: #{err}"
            else
              spawnWrapper '/bin/chown',changeOwner,(err,res)->
                if err?
                  callback "[ERROR] couldn't create vhost: #{err}"
                else
                  log.info info = "[OK] vhost #{domainName} has been created"
                  callback null, info

 # suspendUser : (options,callback)->
 #   #
 #   # This method will suspend OS user:
 #   #
 #   #     * kill all user's processes
 #   #     * lock OS account
 #   #     * compress user's homedir
 #   #     * move compressed archive to config.suspendDir
 #   #
 #   # options =
 #   #   userToSuspend    : String #userToSuspend of the unix user
 #   #

 #   {username, userToSuspend} = options
 #   homeDir = nodePath.join config.usersPath,userToSuspend

 #   # did i really have to write a line like this? C.T.
 #   return unless username in ['chris', 'devrim', 'gokmen']

 #   userInputs = [userToSuspend]
 #   cmd1 = bash "/usr/bin/pkill -u %s -s9", userInputs
 #   killProc = exec cmd1, (err,stdout,stderr)->
 #     if stderr # cant use err there becasue pkill return 1 if no processes was running under #{userToSuspend}
 #       # this should never happens...
 #       log.error "[ERROR] can't kill processes for  #{userToSuspend}: #{stderr}"
 #       callback? "[ERROR] can't kill processes for  #{userToSuspend}: #{stderr}"
 #     else
 #       log.debug "[OK] func:suspendUser: /usr/bin/pkill -u #{userToSuspend} -s9"
 #       userInputs = [userToSuspend, userToSuspend]
 #       cmd2 = bash "tar -v -C #{config.usersPath} -czf #{config.suspendDir}/%s.tar.gz %s", userInputs
 #       compress = exec cmd2,(err,stdout,stderr) ->
 #         if err?
 #           log.error "[ERROR] can't creaate archive #{config.suspendDir}/#{userToSuspend}.tar.gz: #{stderr}"
 #           callback? "[ERROR] can't creaate archive #{config.suspendDir}/#{userToSuspend}.tar.gz: #{stderr}"
 #         else
 #           log.debug "[OK] func:suspendUser: tar -v -C #{config.usersPath} -czf #{config.suspendDir}/#{userToSuspend}.tar.gz #{userToSuspend}"
 #           userInputs = [userToSuspend]
 #           cmd3 = bash "/usr/sbin/usermod -L %s", userInputs
 #           lock = exec cmd3, (err,stdout,stderr) ->
 #             if err?
 #               log.error "[ERROR] can't lock user #{userToSuspend}: #{stderr}"
 #               callback? "[ERROR] can't lock user #{userToSuspend}: #{stderr}"
 #             else
 #               # Measure thrice and cut once
 #               if homeDir is config.usersPath
 #                 log.error "[ERROR] can't remove this dir #{homeDir}"
 #                 callback? "[ERROR] can't remove this dir #{homeDir}"
 #               else
 #                 userInputs = [homeDir]
 #                 cmd4 = bash "/bin/rm -r %s", userInputs
 #                 rmHome = exec cmd4,(err,stdout,stderr)->
 #                   if err?
 #                     log.error "[ERROR] cant remove homedir #{homeDir} for user #{userToSuspend}"
 #                     callback? "[ERROR] cant remove homedir #{homeDir} for user #{userToSuspend}"
 #                   else
 #                     log.debug "[OK] func:suspendUser: /bin/rm -r #{homeDir}"
 #                     log.info "[OK] user was sucsessfully suspended"
 #                     callback? null,"[OK] user was sucsessfully suspended"

 # unSuspendUser : (options,callback)->
 #   #
 #   # This method will unsuspend OS user:
 #   #
 #   #     * unlock OS account
 #   #     * uncompress user's homedir
 #   #     * remove archive from config.suspendDir
 #   #
 #   # options =
 #   #   userToSuspend    : String #userToSuspend of the unix user
 #   #
 #   {userToSuspend, username} = options

 #   return unless username in ['chris', 'devrim', 'gokmen']

 #   homeDir = nodePath.join config.usersPath,userToSuspend

 #   cmd1 = bash "/usr/sbin/usermod -U %s", [userToSuspend]
 #   unlock = exec cmd1, (err,stdout,stderr)->
 #     if err?
 #       callback? "[ERROR] can't unlock user #{userToSuspend}: #{stderr}"
 #     else
 #       log.debug "[OK] func:unSuspendUser: /usr/sbin/usermod -U #{userToSuspend}"
 #       userInputs = [userToSuspend]
 #       cmd2 = bash "tar -C #{config.usersPath} -xzf #{config.suspendDir}/%s.tar.gz", userInputs
 #       uncompress = exec cmd2,(err,stdout,stderr)->
 #         if err?
 #           callback? "[ERROR] can't uncompress user's homedir #{config.suspendDir}/#{userToSuspend}.tar.gz: #{stderr}"
 #         else
 #           log.debug "[OK] func:unSuspendUser: tar -C #{config.usersPath} -xzf #{config.suspendDir}/#{userToSuspend}.tar.gz"
 #           userInputs = [userToSuspend]
 #           cmd3 = bash "rm #{config.suspendDir}/%s.tar.gz", userInputs
 #           rmarchive = exec cmd3, (err,stdout,stderr)->
 #             if err?
 #               e = "[ERROR] can't remove archive #{config.suspendDir}/#{userToSuspend}.tar.gz: #{stderr}"
 #               log.error e; callback? e
 #             else
 #               log.debug "[OK] func:unSuspendUser: rm #{config.suspendDir}/#{userToSuspend}.tar.gz"
 #               userInputs = [userToSuspend]
 #               cmd4 = bash "/usr/sbin/cagefsctl -w %s", userInputs
 #               remount = exec cmd4,(err,stdout,stderr)->
 #                 if err?
 #                   e = "[ERROR] can't remount user #{userToSuspend}: #{stderr}"
 #                   log.error e; callback? e
 #                 else
 #                   log.debug "[OK] func:unSuspendUser: /usr/sbin/cagefsctl -w #{userToSuspend}"
 #                   res = "[OK] user #{userToSuspend} was successfully unsuspended"
