
Bongo              = require 'bongo'
{ Relationship }   = require 'jraphical'
{ join: joinPath } = require 'path'

argv      = require('minimist') process.argv
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")

mongo     = "mongodb://#{ KONFIG.mongo }"
modelPath = '../../workers/social/lib/social/models'
rekuire   = (p)-> require joinPath modelPath, p

koding = new Bongo
  root   : __dirname
  mongo  : mongo
  models : modelPath

console.log "Trying to connect #{mongo} ..."

koding.once 'dbClientReady', ->

  # rekuire your models here like;
  JAccount  = rekuire 'account.coffee'
  JUser     = rekuire 'user/index.coffee'
  JAppStorage     = rekuire 'appstorage.coffee'


  # Config
  # ------

  skip  = 0

  # cache for accounts
  userCache = {}


  # Helpers
  # -------

  # use this to log error on provided index of item
  logError = (err, index)->
    console.log "ERROR on #{index}. >", err  if err?

  # this is an iterator to use on given mongo cursor
  # you must provide a cursor and a function to pass the obj
  # in that cursor, and an index to start from
  iterate = (cursor, func, index, callback)->
    cursor.nextObject (err, obj)->
      if err
        callback err, index
      else if obj?
        func obj, index, (err)->
          index++
          iterate cursor, func, index, callback
      else
        callback null, index

  # fetches the JAccount and JUser of given JAccount.id
  # provides an in memory cache as well
  fetchAccount = (_id, cb)->

    if cached = userCache[_id]
      return cb null, cached

    JAccount.one {_id}, (err, account)->
      return cb err  if err
      return cb {message: "no account found"}  unless account

      JUser.one {username: account.profile.nickname}, (err, user)->
        return cb err  if err
        return cb {message: "no user found"}  unless user

        cb null, userCache[_id] = {user, account}


  fetchAppStorageRelationship = (appStorage, callback) ->

    { appId, version, _id } = appStorage

    query =
      as          : 'appStorage'
      data        : { appId, version }
      targetId    : _id
      targetName  : 'JAppStorage'
      sourceName  : 'JAccount'

    Relationship.one query, (err, rel) ->
      callback err, rel


  migrateAppStorage = (appStorage, index, callback) ->

    console.log "Migrating appStorage with index #{index}"
    { appId, version, _id, bucket } = appStorage

    fetchAppStorageRelationship appStorage, (err, rel) ->
      return callback err  if err

      if not rel
        console.log "No relationship found for appStorage with id #{_id}"
        JAppStorage.remove { _id }, (err) ->
          return callback err

      else
        options = { accountId : rel.sourceId, appId, version, data : bucket }
        JAccount.migrateOldAppStorageIfExists options, (err) ->
          callback err


  # Main updater
  # ------------

  # fetch some data and start ~ for more example check history of this file ~GG

  query = {}
  JAppStorage.count query, (err, appStorageCount) ->
    console.log "#{appStorageCount} appstorages found, starting..."

    fields = { _id : 1, bucket : 1, appId : 1, version : 1 }
    JAppStorage.someData query, fields, { skip }, (err, cursor) ->
      iterate cursor, migrateAppStorage, skip, (err, total) ->
        console.log "ERROR >>", err  if err?
        console.log "FINAL #{total}"
        process.exit 0
