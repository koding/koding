mysql  = require "mysql"
log4js = require 'log4js'
fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'
config = require("./config").mysql

logFile = '/var/log/node/MySQLApi.log'
log     = log4js.addAppender log4js.fileAppender(logFile), "[MySQLApi]"
log     = log4js.getLogger('[MySQLApi]')

class AccessError extends Error
  constructor:(@message)->

class KodingError extends Error
  constructor:(message)->
    return new KodingError(message) unless @ instanceof KodingError
    Error.call @
    @message = message
    @name = 'KodingError'

class MySQL

  escape = (str)->
    str = str+""
    val = str.replace /[\0\n\r\b\t\\\'\"\x1a]/g, (s)->
      switch s
        when "\0" then return "\\0"
        when "\n" then return "\\n"
        when "\r" then return "\\r"
        when "\b" then return "\\b"
        when "\t" then return "\\t"
        when "\x1a" then return "\\Z"
        else return "\\"+s
    return val

  escapeDbName = (str)->
    return str.replace /[^\w\d]/,""

  appendKodingUsername = (username, str)->

    #
    # this will make sure aleksey_aleksey_dbname never happens.
    # corner case, if aleksey wants to create aleksey_aleksey_dbname that won't work either :)
    # f that for now tho.
    #
    str ?= ""
    if str.substr(0,username.length+1) is username+"_"
      return str
    else
      return username+"_"+str

  uniqueId = (length=8) ->

    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  constructor : (@config)->
    @mysqlClient = mysql.createClient @config.databases.mysql[0]
    @dbHost = @config.databases.mysql[0].host

  createUser : (options,callback)->

    #
    # this method will create mysql account
    #

    #
    # options =
    #   dbName   : String     # database name
    #   dbUser   : String     # database user
    #   dbPass   : String     # database pass

    {username,dbUser,dbPass,dbName} = options

    # -------------------------------
    # SECURITY/SANITY FEATURE - NEVER REMOVE
    #
    dbName = appendKodingUsername username,dbName
    dbUser = appendKodingUsername username,dbUser
    # -------------------------------

    dbConf =
      dbName : escape(dbName ? "myDB"+uniqueId())
      dbUser : escape(dbUser.substring(0,16) ? dbName.substring(0,16))
      dbPass : escape(dbPass ? uniqueId())

    log.debug sql = "GRANT ALL ON `#{dbConf.dbName}`.* TO `#{dbConf.dbUser}`@'%' IDENTIFIED BY '#{dbConf.dbPass}'"
    @mysqlClient.query sql,(err)=>
      if err?
        log.error e = "[ERROR] can't create user #{dbConf.dbUser} for #{dbConf.dbName} : #{err}"
        callback new KodingError e
      else
        log.debug "[OK] user #{dbConf.dbUser} for db #{dbConf.dbName} with pass #{dbConf.dbPass} is created"
        callback null, dbConf

  fetchDatabaseList :(options,callback)->

    #
    # this will return the databases of a koding user (not mysql user)
    # it depends on correctly set database names since MySQL has no notion of 'owner'
    # make sure we always create dbs with [username].myName (e.g. devrim.myDbName),
    # then we will count them using this function.
    #

    # options =
    #   username : koding user that makes the call
    #

    {username} = options
    #sql = "SELECT * FROM information_schema.SCHEMATA WHERE SCHEMA_NAME LIKE '#{username}\_%'"
    sql = "SELECT Db,User FROM mysql.db WHERE User LIKE '#{username}\\\_%'"
    console.log "entering with #{sql}"
    @mysqlClient.query sql,callback

  createDatabase : (options,callback)->

    #
    # this method will create mysql database
    #

    #
    # options =
    #   username : koding user that makes the call
    #   dbUser   :
    #   dbPass   :
    #   dbName   : String     # database name
    #

    {username,dbUser,dbName} = options

    dbUser ?= uniqueId()
    dbName ?= dbUser

    dbUser = escape dbUser
    dbName = escape dbName

    # -------------------------------
    # SECURITY/SANITY FEATURE - NEVER REMOVE
    #
    dbName = appendKodingUsername username,dbName
    dbUser = appendKodingUsername username,dbUser

    # we only create aleksey_myDbName kind of databases (dot is not safe to use)
    # so we can count how many databases this user already has.
    # if user is granted permission to another database
    # we know how many he owns, how many he can access separately.
    # -------------------------------

    options.dbName = dbName
    options.dbUser = dbUser

    sendResult = (err,result)=>
      result.dbType = "mysql"
      result.dbHost = @config.databases.mysql[0].host
      console.log "RES: ", result
      callback null,result # return object {dbName:<>,dbUser:<>,dbPass:<>,completedWithErrors:<>}

    dbCount = (username,callback) =>
      @fetchDatabaseList {username},(err,rows)->
        if err then callback err
        else
          callback null,rows.length

    dbCount username,(err,dbNr)=>
      unless err
        unless dbNr > 4 # 0..4
          @mysqlClient.query "CREATE DATABASE `#{dbName}`",(err)=>
            if err?.number is mysql.ERROR_DB_CREATE_EXISTS
              log.error e = "[ERROR] database #{dbName} exists"
              callback new KodingError e
            else if err?
              log.error e = "[ERROR] can't create database: #{err.message}"
              callback new KodingError e
            else
              log.info "[OK] database #{dbName} for user #{dbUser} created"
              @createUser options,(error,result)=>
                if error?
                  # rollback - we don't want inaccessible databases created.
                  @removeDatabase options,(error2,res)=>
                    if err
                      log.error e = "two errors:1-#{error2} 2-#{err}"
                      callback new KodingError e
                    else
                      #res.completedWithErrors = error
                      sendResult null,res
                else
                  sendResult null, result
        else
          callback new KodingError "You exceeded your quota, please delete one before adding a new one."
      else
        callback new KodingError "There was an error completing this request, please try again later."

  changePassword : (options,callback)->

    #
    # this method will change password for mysql account
    #

    #
    # options =
    #   dbUser      : String # database username
    #   newPassword : String # new password
    #

    {username,dbUser,newPassword} = options
    dbUser      = escape dbUser
    newPassword = escape newPassword

    # -------------------------------
    # SECURITY/SANITY FEATURE - NEVER REMOVE
    #
    unless dbUser.substr(0,username.length+1) is username+"_"
      return callback new KodingError "You can only change password of a database user that you own."
    # -------------------------------

    # update user set password=PASSWORD("NEW-PASSWORD-HERE") where User='tom'
    sql = "USE mysql; update user set password=PASSWORD('#{newPassword}') where User='#{dbUser}'; flush privileges"
    @mysqlClient.query sql,(err)=>
      if err?
        log.error e = "[ERROR] can't change password for user #{dbUser} : #{err}"
        callback new KodingError e
      else
        log.info r = "[OK] password for user #{dbUser} has been changed"
        callback null,r

  removeUser : (options,callback)->

    #
    # this method will remove mysql account
    #

    #
    # options =
    #   dbUser      : String # database username
    #

    {username, dbUser}  = options
    dbUser    = escape dbUser

    # -------------------------------
    # SECURITY/SANITY FEATURE - NEVER REMOVE
    #
    unless dbUser.substr(0,username.length+1) is username+"_"
      return callback new KodingError "You can only remove a database user that you own."
    # -------------------------------

    @mysqlClient.query "DROP USER `#{dbUser}`",(err)=>
      if err?
        log.error e = "[ERROR] can't remove user #{dbUser}: #{err}"
        callback new KodingError e
      else
        log.info r = "[OK] user #{dbUser} has been removed"
        callback null,r

  removeDatabase : (options,callback)->

    #
    # this method will remove mysql database and related account
    #

    #
    # options =
    #   dbUser   : String # database username
    #   dbName   : String # database name
    #

    {username,dbUser,dbName} = options
    dbName          = escape dbName

    # -------------------------------
    # SECURITY/SANITY FEATURE - NEVER REMOVE
    #
    console.log dbUser.substr(0,username.length+1)
    console.log username+"_"
    console.log dbName.substr(0,username.length+1)

    unless dbUser.substr(0,username.length+1) is username+"_" and dbName.substr(0,username.length+1) is username+"_"
      return callback new KodingError "You can only remove a database that you own."
    # -------------------------------


    @removeUser options,(error,result)=>
      log.warn e = "can't remove the user:#{dbUser}, trying to drop the database anyway. #{error ? ''}" if error
      @mysqlClient.query "DROP DATABASE `#{dbName}`",(err)=>
        if err?
          log.error e = "[ERROR] can't remove database #{dbName} : #{err}"
          callback new KodingError e
        else
          log.info r = "[OK] database #{dbName} with user #{dbUser} has been removed. Errors:#{e ? 'none'}"
          callback null,r


  # checkBackupDir : (options,callback)->
  #
  #   #
  #   # this method will check backupDir
  #   # if doesn't exists  - create it
  #   #
  #
  #   #
  #   # options =
  #   #   username : String # Kodingen username
  #   #   dbName   : String # database name
  #   #   dbUser   : String # database username
  #   #   dbPass   : String # database name
  #
  #   {username,dbName} = options
  #
  #   # first check /Users/<username>/Backups/mysql/<dbName>
  #   backupDir = path.join @config.usersPath,username,@config.backupDir,dbName
  #   fs.stat backupDir,(err,stats)->
  #     if err?
  #       log.debug "[ERROR] backup directory #{backupDir} doesn't exists -> creating"
  #       child = exec "su -l #{username} -c 'mkdir -p #{backupDir}'",(err,stdout,stderr)->
  #         if err?
  #           log.error e = "[ERROR] can't create backup dir #{backupDir}: #{stderr}"
  #           callback? e
  #         else
  #           log.info "[OK] backup directory #{backupDir} created -> creating backup"
  #           callback null,backupDir
  #     else
  #       log.debug "[OK] directory #{backupDir} exitsts -> creating backup"
  #       callback? null,backupDir


  # backupDatabase : (options,callback)->
  #
  #   #
  #   # this method will create backup of mysql database to the /Users/<username>/Backups/
  #   #
  #
  #   #
  #   # options =
  #   #   username : String # Kodingen username
  #   #   dbName   : String # database name
  #   #   dbUser   : String # database username
  #   #   dbPass   : String # database name
  #
  #   {username,dbName,dbUser,dbPass} = options
  #
  #   d = new Date()
  #   timeStamp = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDay()}-#{d.getHours()}-#{d.getMinutes()}-#{d.getSeconds()}"
  #   @checkBackupDir options,(error,backupDir)=>
  #     if error?
  #       callabck? error
  #     else
  #       # TODO: permissions
  #       child = exec "/usr/bin/mysqldump -h #{@config.databases.mysql.host}  --opt -u '#{dbUser}' -p'#{dbPass}' '#{dbName}' > #{backupDir}/'#{dbName}'-#{timeStamp}.sql",(err,stdout,stderr)->
  #         if err?
  #           log.error e = "[ERROR] can't create database dump for #{dbName} : #{stderr}"
  #           callback? e
  #         else
  #           log.info r = "[OK] database dump for #{dbName} created in #{backupDir}/#{dbName}-#{timeStamp}.sql"
  #           callback? null,r

mySQL = new MySQL config
module.exports = mySQL

# mySQL.test()

#options =
#  username : "aleksey-m"
#  dbName   : "aleksey-m_132"
#  dbUser   : "aleksey-m_132"
  #dbPass   : "ls;kls;ka;ska;sk"
#
#mySQL.removeDatabase options , (err,res)->
#   console.log "removing"
#   console.log options
#   console.log "err:#{err}", res

#mySQL.createDatabase options , (err,res)->
#   console.log "creating"
#   console.log options
#   console.log "err:#{err}", res
#
###
#mySQL.backupDatabase options,(error,result)->
#  if error?
#    console.error error
#  else
#    console.log result
#
