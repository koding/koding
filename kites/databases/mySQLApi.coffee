mysql  = require "mysql"
log4js = require 'log4js'
fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'
config = require("./config").mysql

logFile = '/var/log/node/MySQLApi.log'
log     = log4js.addAppender log4js.fileAppender(logFile), "[MySQLApi]"
log     = log4js.getLogger('[MySQLApi]')




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

  constructor : (@config)->
    @mysqlClient = mysql.createClient @config.databases.mysql

    
  uniqueId = (length=8) ->

    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

    
  createUser : (options,callback)->

    #
    # this method will create mysql account
    #

    #
    # options =
    #   dbName   : String     # database name
    #   dbUser   : String     # database user
    #   dbPass   : String     # database pass

    {dbUser,dbPass,dbName} = options

    dbConf =
      dbName : escape(dbName ? "myDB"+uniqueId())
      dbUser : escape(dbUser.substring(0,16) ? dbName.substring(0,16))
      dbPass : escape(dbPass ? uniqueId())

    log.debug sql = "GRANT ALL ON #{dbConf.dbName}.* TO #{dbConf.dbUser}@'%' IDENTIFIED BY '#{dbConf.dbPass}'"
    @mysqlClient.query sql,(err)=>
      if err?
        log.error e = "[ERROR] can't create user #{dbConf.dbUser} for #{dbConf.dbName} : #{err}"
        callback e
      else
        log.debug "[OK] user #{dbConf.dbUser} for db #{dbConf.dbName} with pass #{dbConf.dbPass} is created"
        callback null, dbConf

  createDatabase : (options,callback)->

    #
    # this method will create mysql database
    #

    #
    # options =
    #   dbUser   :
    #   dbPass   :
    #   dbName   : String     # database name
    #

    {dbUser,dbName} = options
    
    dbUser = escape dbUser
    dbName = escape dbName
    
    sendResult = (err,result)=>
      result.host = @config.databases.mysql.host          
      callback null,result # return object {dbName:<>,dbUser:<>,dbPass:<>,completedWithErrors:<>}

    @mysqlClient.query "CREATE DATABASE #{dbName}",(err)=>
      if err?.number is mysql.ERROR_DB_CREATE_EXISTS
        log.error e = "[ERROR] database #{dbName} exists"
        callback e
      else if err?
        log.error e = "[ERROR] can't create database: #{err.message}"
        callback e
      else
        log.info "[OK] database #{dbName} for user #{dbUser} created"
        @createUser options,(error,result)=>
          if error?
            # rollback - we don't want inaccessible databases created.
            @removeDatabase options,(error2,res)=>
              if err
                log.error e = "two errors:1-#{error2} 2-#{err}"
                callback e
              else
                res.completedWithErrors = error
                sendResult null,res
          else
            sendResult null,result
    


  changePassword : (options,callback)->

    #
    # this method will change password for mysql account
    #

    #
    # options =
    #   dbUser      : String # database username
    #   newPassword : String # new password
    #

    {dbUser,newPassword} = options
    dbUser      = escape dbUser
    newPassword = escape newPassword
    # update user set password=PASSWORD("NEW-PASSWORD-HERE") where User='tom'
    sql = "USE mysql; update user set password=PASSWORD('#{newPassword}') where User='#{dbUser}'; flush privileges"
    @mysqlClient.query sql,(err)=>
      if err?
        log.error e = "[ERROR] can't change password for user #{dbUser} : #{err}"
        callback e
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

    {dbUser}  = options
    dbUser    = escape dbUser
    @mysqlClient.query "DROP USER #{dbUser}",(err)=>
      if err?
        log.error e = "[ERROR] can't remove user #{dbUser}: #{err}"
        callback e
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

    {dbUser,dbName} = options
    dbName          = escape dbName
    
    @removeUser options,(error,result)=>
      log.warn e = "can't remove the user:#{dbUser}, trying to drop the database anyway. #{error ? ''}" if error
      
      @mysqlClient.query "DROP DATABASE #{dbName}",(err)=>
        if err?
          log.error e = "[ERROR] can't remove database #{dbName} : #{err}"
          callback e
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

  test:((options,callback)->
     @mysqlClient.query "SELECT user FROM mysql.user",(err,data)->
      console.log arguments
  )()


mySQL = new MySQL config

module.exports = mySQL




###
options =
  username : "aleksey007"
  dbName   : "dbtester_1325887572490"
  dbUser   : "dbtester_1325887"
  dbPass   : "ls;kls;ka;ska;sk"

mySQL.backupDatabase options,(error,result)->
  if error?
    console.error error
  else
    console.log result




