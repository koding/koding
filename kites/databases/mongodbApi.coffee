mongo   = require 'mongodb'
log4js  = require 'log4js'
config  = require('./config').mongo
{daisy} = require "sinkrow"
logFile = '/var/log/node/MongoDBApi.log'
#log     = log4js.addAppender log4js.fileAppender(logFile), "[MongoDBApi]"
log     = log4js.getLogger('[MongoDBApi]')

class AccessError extends Error
  constructor:(@message)->

class KodingError extends Error
  constructor:(message)->
    return new KodingError(message) unless @ instanceof KodingError
    Error.call @
    @message = message
    @name = 'KodingError'

class MongoDB

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

  constructor : (@config)->

    @mongoHost = @config.databases.mongodb[0].host
    @mongoUser = @config.databases.mongodb[0].user
    @mongoPass = @config.databases.mongodb[0].password
    @server = new mongo.Server @mongoHost, 27017, socketOptions:keepAlive:5

  uniqueId = (length=8) ->

    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  getDbUsers : (dbName,callback)->

    db = new mongo.Db dbName, @server, native_parser: false
    db.open (err,db)=>
      if err?
        log.error error = "[ERROR] can't open database #{dbName}: #{err}"
      else
        db.admin().authenticate @mongoUser, @mongoPass,(err,result)=>
          log.error err if err
          db.collection "system.users",(err,collection)=>
            log.error err if err
            collection.find({},{fields:user:1}).toArray (err,items)->
              log.error err if err
              db.close() # temporary solotion - close connection after each query
              usernames = []
              for user in items
                usernames.push user.user
              callback usernames

  fetchDatabaseList :(options, callback)->
    #
    # options =
    #   username : koding user

    {username} = options
    username = new RegExp '^'+username+'_'

    db = new mongo.Db 'admin', @server, native_parser: false

    db.open (err,db)=>
      if err?
        log.error error = "[ERROR] can't open database #{dbConf.dbName}: #{err}"
        callback? error
      else
        db.admin (err,adm)=>
          adm.authenticate @mongoUser, @mongoPass,(err)=>
            if err?
              console.log error = "[ERROR] " + err
              callback? error
            else
              adm.command listDatabases:1, (err,result)=>
                if err?
                  log.error error = "[ERROR]: #{err}"
                  callback? error
                else
                  users_dbs = []
                  dbInfo = []
                  for db in result.documents[0].databases
                    users_dbs.push db.name if db.name.match username
                  queue = []
                  users_dbs.forEach (users_db, index)=>
                    queue.push =>
                      @getDbUsers users_db, (usersArray)=>
                        if users_db in usersArray
                          dbInfo.push { dbName: users_db, dbUser: users_db, dbType: 'mongo', dbHost:@mongoHost }
                        queue.next()
                  queue.push ->
                    callback null, dbInfo
                  daisy queue


  createDatabase : (options,callback)->

    #
    # this method will create mongo database
    #

    #
    # options =
    #   username : koding user that makes the call
    #   dbUser    : String # db username
    #   dbName    : String # database name
    #   dbPass    : String that holds the password
    #

    {username,dbUser,dbName,dbPass} = options

    # -------------------------------
    # SECURITY/SANITY FEATURE - NEVER REMOVE
    #
    dbName = appendKodingUsername username,dbName
    dbUser = appendKodingUsername username,dbUser
    #
    # we only create aleksey_myDbName kind of databases (dot is not safe to use)
    # so we can count how many databases this user already has.
    # if user is granted permission to another database
    # we know how many he owns, how many he can access separately.
    # -------------------------------

    dbConf = {dbName,dbUser,dbPass}

    dbConf.dbHost = @mongoHost
    dbConf.dbType = "mongo"

    dbConf.dbPass = uniqueId()
    dbConf.dbUser = dbConf.dbName

    console.log dbConf

    db = new mongo.Db dbConf.dbName, @server

    dbCount = (username,callback) =>
      @fetchDatabaseList username:username,(err,dbsArray)->
        if err
          callback err
        else
          callback null,dbsArray.length

    dbCount username,(err,dbNr)=>
      unless err
        if dbNr > 4 # 0..4
          log.error e = "You exceeded your quota, please delete one before adding a new one."
          callback new KodingError e
        else
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
                        log.info dbConf
                        callback? null,dbConf

  changePassword : (options,callback)->

    #
    # this method will change password for mongodb account
    #

    #
    # options =
    #   dbPass          : String # current users's password
    #   newPassword     : String # new password
    #

    {username,dbUser,newPassword} = options

    db = new mongo.Db dbUser, @server
    db.open (err,db)=>
      db.admin().authenticate @mongoUser, @mongoPass,(err,result)=>
        if err?
          log.error "[ERROR] can't authenticate user #{dbUser} with current password: #{err}"
          callback? "[ERROR] can't authenticate user #{dbUser} with current password: #{err}"
        else
          db.addUser dbUser,newPassword,(err,result)->
            db.authenticate dbUser,newPassword,(err,result)->
              if err?
                log.error "[ERROR] can't change password for user #{dbUser} in databse #{dbUser}: #{err}"
                callback? "[ERROR] can't change password for user #{dbUser} in databse #{dbUser}: #{err}"
              else
                log.info "[OK] password for user #{dbUser} in database #{dbUser} has been changed"
                callback? null,"[OK] password for user #{dbUser} in database #{dbUser} has been changed"

  removeDatabase : (options,callback)->

    #
    # this method will remove mongodb database and related account
    #

    #
    # options =
    #   username : Koding Username
    #   dbUser   : String # database username
    #   dbName   : String # database name
    #

    {username,dbUser,dbName} = options

    # -------------------------------
    # SECURITY/SANITY FEATURE - NEVER REMOVE
    #
    console.log dbUser.substr(0,username.length+1)
    console.log username+"_"
    console.log dbName.substr(0,username.length+1)

    unless dbUser.substr(0,username.length+1) is username+"_" and dbName.substr(0,username.length+1) is username+"_"
      return callback new KodingError "You can only remove a database that you own."
    # -------------------------------


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

