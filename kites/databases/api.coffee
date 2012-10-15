config    = require "./config"
mySQL     = require './mySQLApi'
mongoDB   = require './mongodbApi'


Kite      = require '../../node_modules/kite-amqp'
log4js    = require 'log4js'
log       = log4js.getLogger("[#{config.name}]")


log4js.addAppender log4js.fileAppender(config.logFile), config.name if config.logFile?


__resReport = (error,result,callback)->
  if error
    callback? wrapErr error
  else
    callback? null,result

wrapErr = (err)->
  message : err.message
  stack   : err.stack

# class AccessError extends Error
#   constructor:(@message)->

# class KodingError extends Error
#   constructor:(message)->
#     return new KodingError(message) unless @ instanceof KodingError
#     Error.call @
#     @message = message
#     @name = 'KodingError'

# this.Error = KodingError

module.exports = new Kite 'databases'

  #**********************************************#
  #***************** MySQL **********************#
  #**********************************************#

  fetchMysqlDatabases : (options, callback)->

    # this method will list mysql databases for the user
    # object will be returned:

    #
    # options =
    #   username : String # Kodingen username, db username will be generated wiht username+dbName (db username max 16 symbols, will be truncated)
    #     ^^^^ wrong - this kite should not know anything about how kodingen works

    mySQL.fetchDatabaseList options,(error,result)->
      result.forEach (set)->
        set.dbName = set.Db
        delete set.Db
        set.dbUser = set.User
        delete set.User
        set.dbType = 'mysql'
        set.dbHost = mySQL.dbHost
      __resReport(error,result,callback)

  createMysqlDatabase : (options,callback)->

    # this method will create mysql database and user
    # object will be returned:
    # { dbName: '<String>',
    #   dbUser: '<String>',
    #   dbPass: '<String>' }

    #
    # options =
    #   username : String # Kodingen username, db username will be generated wiht username+dbName (db username max 16 symbols, will be truncated)
    #     ^^^^ wrong - this kite should not know anything about how kodingen works
    #                  if kodingen wants to put a prefix, it will do so from its kfmjs.
    #   dbName   : String # database name
    #

    console.log options
    mySQL.createDatabase options,(error,result)->
      __resReport(error,result,callback)

  changeMysqlPassword : (options,callback)->

    # this method will change password for database account

    #
    # options =
    #   dbUser      : String # database username
    #   newPassword : String # new password
    #

    mySQL.changePassword options,(error,result)->
      __resReport(error,result,callback)

  removeMysqlDatabase : (options,callback)->

    # this method will remove mysql database and related account

    #
    # options =
    #   dbUser   : String # database username
    #   dbName   : String # database name
    #

    mySQL.removeDatabase options,(error,result)->
      __resReport(error,result,callback)

  #**********************************************#
  #***************** end of MySQL ***************#
  #**********************************************#



  #**********************************************#
  #***************** MongoDB ********************#
  #**********************************************#

  fetchMongoDatabases : (options, callback)->

    # this method will list mysql databases for the user
    # object will be returned:

    #
    # options =
    #   username : String # Kodingen username, db username will be generated wiht username+dbName (db username max 16 symbols, will be truncated)
    #     ^^^^ wrong - this kite should not know anything about how kodingen works

    mongoDB.fetchDatabaseList options,(error,result)->
      __resReport(error,result,callback)

  createMongoDatabase : (options,callback)->

    # this method will create mongoDB database and user
    # object will be returned:
    # { dbName: '<String>',
    #   dbUser: '<String>',
    #   dbPass: '<String>' }

    #
    # options =
    #   username : String # Kodingen username, db username will be generated wiht username+dbName
    #   dbName   : String # database name
    #


    mongoDB.createDatabase options,(error,result)->
      __resReport(error,result,callback)


  changeMongoPassword : (options,callback)->

      # this method will change password for mongo database account

      #
      # options =
      #   dbUser          : String # database username
      #   dbName          : String # database name
      #   dbPass          : String # current users's password
      #   newPassword     : String # new password
      #


    mongoDB.changePassword options,(error,result)->
      __resReport(error,result,callback)


  removeMongoDatabase : (options,callback)->

      # this method will remove mysql database and related account

      #
      # options =
      #   dbName   : String # database name
      #   dbUser   : String # database username
      #   dbPass   : String # user's password
      #

    mongoDB.removeDatabase options,(error,result)->
      __resReport(error,result,callback)


