config    = require './config'

log4js    = require 'log4js'
log       = log4js.getLogger("[#{config.name}]")

nodePath  = require 'path'
{exec}    = require 'child_process'
fs        = require 'fs'
hat       = require 'hat'
os        = require 'os'
ldap      = require 'ldapjs'
Kite      = require 'kite-amqp'
mkdirp    = require 'mkdirp'

createTmpDir = require './createtmpdir'

console.log "new sharedhosting api."

escapePath = (name)-> return name.replace(/\'/g, '\\\'').replace(/\"/g, '\\"').replace(/\s/g, '\\ ')

makedirp = (path, user, cb)->
  exec "mkdir -p #{path} && chown #{user}: #{path}", cb

createAppsDir = (user, cb)->
  path = escapePath "/Users/#{user}/Applications"
  makedirp path, user, cb

module.exports = new Kite 'sharedHosting'


  timeout:({timeout}, callback)->
    setTimeout (-> callback null, timeout), timeout

  interval:({interval}, callback)->
    setInterval (-> callback null, interval), interval

  executeCommand: require './executecommand'

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
          @executeCommand {username,command:"cp #{tmpPath} #{path}"}, (err,res)->
            unless err
              callback? null,path
            else
              callback? "[ERROR] can't upload file : #{err}"



  checkUid:(options,callback)->
    #
    # This methid will check user's uid
    #
    #
    # options =
    #   username : String  #username of the unix user
    #
    {username,nrOfRecursion} = options

    getuid = exec "/usr/bin/id -u #{username}", (err,stdout,stderr)=>
      if err?
        log.error "[ERROR] unable to get user's UID: #{stderr}"
        if nrOfRecursion is 1
          callback?  "[ERROR] unable to get user's UID, can't create user: #{stderr}"
        else
          @createSystemUser {username,fullName:username,password:hat()},(err,res)=>
            unless err
              log.info "User is just created, run the command again, it will work this time."
              @checkUid {username,nrOfRecursion:1},callback
            else
              log.error "CANT CREATE THIS USER"
              callback?  "[ERROR] unable to get user's UID, can't create user: #{stderr}"


      else if stdout < config.minAllowedUid
        stdout = stdout.replace(/(\r\n|\n|\r)/gm," ")
        log.error e = "[ERROR]  min UID for commands is #{config.minAllowedUid}, your #{stdout}"
        callback? e
      else
        stdout = stdout.replace(/(\r\n|\n|\r)/gm," ")
        log.debug "[OK] func:checkUid: user's #{username} UID #{stdout} allowed"
        callback? null

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

    {username,uid} = options
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

  copyAppSkeleton:(options, callback)->
    {username, appPath, type} = options

    appPath = escapePath "#{appPath}/"
    type = "blank" if not type in ["blank", "sample"]

    exec "cp -r /opt/Apps/.defaults/#{type}/* #{appPath}", (err, stdout, stderr)->
      if not err
        exec "chown -R #{username}: #{appPath}", (err, stdout, stderr)->
          console.error err if err
          callback err
      else
        console.error err if err
        callback err

  publishApp:(options, callback)->

    {username, profile, version, appName, userAppPath} = options

    appRootPath   = escapePath "/opt/Apps/#{username}/#{appName}"
    latestPath    = escapePath "/opt/Apps/#{username}/#{appName}/latest"
    versionedPath = escapePath "/opt/Apps/#{username}/#{appName}/#{version}"
    userAppPath   = escapePath userAppPath

    cb = (err)->
      console.error err if err
      callback? err, null

    createAppsDir username, (err)->
      makedirp appRootPath, username, (err)->
        if err then cb err
        else
          exec "test -d #{versionedPath}", (err, stdout, stderr)->
            unless err or stderr.length then cb "[ERROR] Version is already published, change version and try again!"
            else
              exec "cp -r #{userAppPath} #{versionedPath}", (err, stdout, stderr)->
                if err or stderr then cb err
                else
                  manifestPath = "#{versionedPath}/.manifest"
                  exec "cat #{manifestPath}", (err, stdout, stderr)->
                    if err or stderr then cb err
                    else
                      exec "rm -f #{manifestPath}", ->
                        manifest = JSON.parse stdout
                        manifest.author = "#{profile.firstName} #{profile.lastName}"
                        manifest.authorNick = username
                        delete manifest.devMode if manifest.devMode
                        unescapedManifestPath = "/opt/Apps/#{username}/#{appName}/#{version}/.manifest"
                        fs.writeFile unescapedManifestPath, JSON.stringify(manifest, null, 2), 'utf8', cb

  downloadApp: (options, callback)->

    {username, owner, appName, version, appPath} = options

    cb = (err)->
      console.error err if err
      callback? err, null

    version   or= 'latest'
    kpmAppPath  = escapePath "/opt/Apps/#{owner}/#{appName}/#{version}"
    userAppPath = escapePath appPath
    backupPath  = "#{appPath}.org.#{(Date.now()+'').substr(-4)}"

    console.log kpmAppPath
    console.log userAppPath
    console.log backupPath

    # mkdirp backupPath, (err)->
    #   if err then cb err
    #   else
    #     cb null
    exec "test -d #{kpmAppPath}", (err, stdout, stderr)->
      if err or stderr.length
        cb "[ERROR] App files not found! Download cancelled."
      else
        exec "mv #{userAppPath} #{backupPath} && cp -r #{kpmAppPath}/ #{userAppPath} && chown -R #{username}: #{userAppPath}", (err, stdout, stderr)->
          if err or stderr then cb err
          else
            cb null

  installApp: (options, callback)->

    {username, owner, appPath, appName, version} = options
    version ?= 'latest'

    cb = (err)->
      console.error err if err
      callback? err, null

    kpmAppPath = escapePath "/opt/Apps/#{owner}/#{appName}/#{version}"
    appPath    = escapePath appPath

    createAppsDir username, (err)->
      makedirp appPath, username, (err)->
        if err then cb err
        else
          exec "cp #{kpmAppPath}/index.js #{appPath} && cp #{kpmAppPath}/.manifest #{appPath}", (err, stdout, stderr)->
            if err or stderr.length
              cb err or "[ERROR] #{stderr}"
            else
              exec "chown -R #{username}: #{appPath}", (err, stdout, stderr)->
                if err or stderr.length
                  cb err or "[ERROR] #{stderr}"
                else
                  cb null

  approveApp: (options, callback)->

    {username, authorNick, version, appName} = options

    appRootPath   = escapePath "/opt/Apps/#{authorNick}/#{appName}"
    latestPath    = escapePath "/opt/Apps/#{authorNick}/#{appName}/latest"
    versionedPath = escapePath "/opt/Apps/#{authorNick}/#{appName}/#{version}"

    cb = (err)->
      console.error err if err
      callback? err, null

    exec "test -d #{versionedPath}", (err, stdout, stderr)->
      if err or stderr.length
        cb "[ERROR] Version is not exists!", version
      else
        exec "rm -f #{latestPath} && ln -s #{versionedPath} #{latestPath}", (err, stdout, stderr)->
          if err or stderr then cb err
          else cb null

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

  createVhost : (options,callback)->

    {username,uid,domainName} = options

    domainName ?= "#{username}.#{config.defaultDomain}"
    targetPath = "/Users/#{username}/Sites/#{domainName}"
    cmd        = "mkdir -p #{targetPath} && cp -r #{config.defaultVhostFiles}/website #{targetPath} && chown #{uid}:#{uid} -R #{targetPath}/*"
    cmd       += " && echo 'curl https://koding.com/koding-announcement.txt' > /Users/#{username}/.bashrc && chown #{uid}:#{uid} /Users/#{username}/.bashrc"
    log.debug "executing CreateVhost:",cmd

    exec cmd,(err,stdout,stderr)->
      unless err
        callback null, "vhost created with default files:",domainName
      else
        log.error stderr
        callback stderr

  changePassword : (options,callback)->
    #
    # This method will change OS password for user
    #
    #
    # options =
    #   username    : String #username of the unix user
    #   newPassword : String #fullName - real name for unux user
    #

    {username,newPassword} = options

    chpw = exec "echo '#{newPassword}' | /usr/bin/passwd --stdin #{username}", (err,stdout,stderr)=>
      if err?
        log.error "[ERROR] can't set password for #{username}: #{stderr}"
        callback? "[ERROR] can't set password for #{username}: #{stderr}"
      else
        log.info "[OK] password for #{username} was successfully changed"
        callback? null,"[OK] password for #{username} was successfully changed"


  suspendUser : (options,callback)->
    #
    # This method will suspend OS user:
    #
    #     * kill all user's processes
    #     * lock OS account
    #     * compress user's homedir
    #     * move compressed archive to config.suspendDir
    #
    # options =
    #   username    : String #username of the unix user
    #

    {username} = options
    homeDir = nodePath.join config.usersPath,username

    killProc = exec "/usr/bin/pkill -u #{username} -s9", (err,stdout,stderr)->
      if stderr # cant use err there becasue pkill return 1 if no processes was running under #{username}
        # this should never happens...
        log.error "[ERROR] can't kill processes for  #{username}: #{stderr}"
        callback? "[ERROR] can't kill processes for  #{username}: #{stderr}"
      else
        log.debug "[OK] func:suspendUser: /usr/bin/pkill -u #{username} -s9"
        compress = exec "tar -v -C #{config.usersPath} -czf #{config.suspendDir}/#{username}.tar.gz #{username}",(err,stdout,stderr) ->
          if err?
            log.error "[ERROR] can't creaate archive #{config.suspendDir}/#{username}.tar.gz: #{stderr}"
            callback? "[ERROR] can't creaate archive #{config.suspendDir}/#{username}.tar.gz: #{stderr}"
          else
            log.debug "[OK] func:suspendUser: tar -v -C #{config.usersPath} -czf #{config.suspendDir}/#{username}.tar.gz #{username}"
            lock = exec "/usr/sbin/usermod -L #{username}", (err,stdout,stderr) ->
              if err?
                log.error "[ERROR] can't lock user #{username}: #{stderr}"
                callback? "[ERROR] can't lock user #{username}: #{stderr}"
              else
                # Measure thrice and cut once
                if homeDir is config.usersPath
                  log.error "[ERROR] can't remove this dir #{homeDir}"
                  callback? "[ERROR] can't remove this dir #{homeDir}"
                else
                  rmHome = exec "/bin/rm -r #{homeDir}",(err,stdout,stderr)->
                    if err?
                      log.error "[ERROR] cant remove homedir #{homeDir} for user #{username}"
                      callback? "[ERROR] cant remove homedir #{homeDir} for user #{username}"
                    else
                      log.debug "[OK] func:suspendUser: /bin/rm -r #{homeDir}"
                      log.info "[OK] user was sucsessfully suspended"
                      callback? null,"[OK] user was sucsessfully suspended"

  unSuspendUser : (options,callback)->
    #
    # This method will unsuspend OS user:
    #
    #     * unlock OS account
    #     * uncompress user's homedir
    #     * remove archive from config.suspendDir
    #
    # options =
    #   username    : String #username of the unix user
    #
    {username} = options
    homeDir = nodePath.join config.usersPath,username
    unlock = exec "/usr/sbin/usermod -U #{username}", (err,stdout,stderr)->
      if err?
        callback? "[ERROR] can't unlock user #{username}: #{stderr}"
      else
        log.debug "[OK] func:unSuspendUser: /usr/sbin/usermod -U #{username}"
        uncompress = exec "tar -C #{config.usersPath} -xzf #{config.suspendDir}/#{username}.tar.gz",(err,stdout,stderr)->
          if err?
            callback? "[ERROR] can't uncompress user's homedir #{config.suspendDir}/#{username}.tar.gz: #{stderr}"
          else
            log.debug "[OK] func:unSuspendUser: tar -C #{config.usersPath} -xzf #{config.suspendDir}/#{username}.tar.gz"
            rmarchive = exec "rm #{config.suspendDir}/#{username}.tar.gz",(err,stdout,stderr)->
            if err?
              e = "[ERROR] can't remove archive #{config.suspendDir}/#{username}.tar.gz: #{stderr}"
              log.error e; callback? e
            else
              log.debug "[OK] func:unSuspendUser: rm #{config.suspendDir}/#{username}.tar.gz"
              remount = exec "/usr/sbin/cagefsctl -w #{username}",(err,stdout,stderr)->
                if err?
                  e = "[ERROR] can't remount user #{username}: #{stderr}"
                  log.error e; callback? e
                else
                  log.debug "[OK] func:unSuspendUser: /usr/sbin/cagefsctl -w #{username}"
                  res = "[OK] user #{username} was successfully unsuspended"
                  log.info res; callback? null, res

