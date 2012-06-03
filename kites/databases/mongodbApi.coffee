mongo   = require 'mongodb'
log4js  = require 'log4js'
config  = require('config').mongo


logFile = '/var/log/node/MongoDBApi.log'
log     = log4js.addAppender log4js.fileAppender(logFile), "[MongoDBApi]"
log     = log4js.getLogger('[MongoDBApi]')


class MongoDB

  constructor : (@config)->

    @mongoHost = @config.databases.mongodb.host
    @mongoUser = @config.databases.mongodb.user
    @mongoPass = @config.databases.mongodb.password
    @server = new mongo.Server @mongoHost, 27017

  uniqueId = (length=8) ->

    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  createDatabase : (options,callback)->

    #
    # this method will create mongo database
    #

    #
    # options =
    #   dbUser    : String # db username
    #   dbName    : String # database name
    #   dbPass    : String that holds the password
    #

    {dbUser,dbName,dbPass} = options
    
    dbConf = {dbName,dbUser,dbPass}
    dbConf.host = @config.databases.mongodb.host

    db = new mongo.Db dbConf.dbName, @server

    db.open (err,db)=>
      if err?
        log.error "[ERROR] can't open database #{dbConf.dbName}: #{err}"
        callback? "[ERROR] can't open database #{dbConf.dbName}: #{err}"
      else
        db.admin().authenticate @mongoUser, @mongoPass,(err,result)=>
          if err?
            log.error "[ERROR] can't authenticate with admin credentials: #{err}"
            callback?  "[ERROR] can't authenticate with admin credentials: #{err}"
          else
            db.addUser dbConf.dbUser,dbConf.dbPass,(err,res)->
              log.debug err,res
              db.authenticate dbConf.dbUser,dbConf.dbPass,(err,res)->
                if err?
                  log.error "[ERROR] can't create user #{dbConf.dbUser} and database #{dbConf.dbName}: #{err}"
                  callback? "[ERROR] can't create user #{dbConf.dbUser} and database #{dbConf.dbName}: #{err}"
                else
                  log.debug res
                  log.info "[OK] user #{dbConf.dbUser} and database #{dbConf.dbName} has been created"
                  callback? null,dbConf

  changePassword : (options,callback)->

    #
    # this method will change password for mongodb account
    #

    #
    # options =
    #   dbUser          : String # database username
    #   dbName          : String # database name
    #   dbPass          : String # current users's password
    #   newPassword     : String # new password
    #

    {dbUser,dbName,dbPass,newPassword} = options

    db = new mongo.Db dbName, @server
    db.open (err,db)=>
      db.admin().authenticate @mongoUser, @mongoPass,(err,result)=>
        if err?
          log.error "[ERROR] can't authenticate user #{dbUser} with current password: #{err}"
          callback? "[ERROR] can't authenticate user #{dbUser} with current password: #{err}"
        else
          db.addUser dbUser,newPassword,(err,result)->
            db.authenticate dbUser,newPassword,(err,result)->
              if err?
                log.error "[ERROR] can't change password for user #{dbUser} in databse #{dbName}: #{err}"
                callback? "[ERROR] can't change password for user #{dbUser} in databse #{dbName}: #{err}"
              else
                log.info "[OK] password for user #{dbUser} in database #{dbName} has been changed"
                callback? null,"[OK] password for user #{dbUser} in database #{dbName} has been changed"






  removeDatabase : (options,callback)->

    #
    # this method will remove mongodb database and related account
    #

    #
    # options =
    #   dbName   : String # database name
    #   dbUser   : String # database username
    #
    
    {dbUser,dbName} = options
    log.debug options
    db = new mongo.Db dbName, @server
    db.open (err,db)=>
      db.admin().authenticate @mongoUser, @mongoPass,(err,result)=>
        if err?
          log.error "[ERROR] can't authenticate user #{dbUser} in #{dbName} with current password: #{err}"
          callback? "[ERROR] can't authenticate user #{dbUser} in #{dbName} with current password: #{err}"
        else
          db.dropDatabase (err,result)->
            if err?
              log.error "[ERROR] can't drop database #{dbName}"
              callback?  "[ERROR] can't drop database #{dbName}"
            else
              log.info "[OK] database #{dbName} has been removed"
              callback? null,"[OK] database #{dbName} has been removed"

mongoDB = new MongoDB config

module.exports = mongoDB


