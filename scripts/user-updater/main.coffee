
Bongo              = require 'bongo'
{ Relationship }   = require 'jraphical'
{ join: joinPath } = require 'path'
{ dash }           = Bongo

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
  JAccount    = rekuire 'account.coffee'
  JUser       = rekuire 'user/index.coffee'
  JAppStorage = rekuire 'appstorage.coffee'


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
      userCache[_id] = {account}
      cb null, userCache[_id]


  migrateAppStorages = (account, index, callback) ->

    console.log "Starting migrate app storages, Index: #{index}, AccountId: #{account._id}"

    fetchAccount account._id, (err, { account }) ->
      return callback err  if err
      return callback new KodingError 'no account'  unless account

      account.fetchAppStorages (err, storages) ->
        return callback err  if err

        queue = []
        storages.forEach (storage) ->
          { appId, version } = storage

          queue.push ->
            account.migrateOldAppStorageIfExists { appId, version }, (err) ->
              console.log "Migrating appStorage with id #{storage._id}"
              console.log "Error on appStorage with id #{storage._id}"  if err
              queue.fin()

        dash queue, (err) ->
          logError err, index
          return callback err


  # Main updater
  # ------------

  # fetch some data and start ~ for more example check history of this file ~GG

  query = {}
  JAccount.count query, (err, accountCount) ->
    console.log "#{accountCount} accounts found, starting..."

    fields = { _id : 1 }
    JAccount.someData query, fields, { skip }, (err, cursor) ->
      iterate cursor, migrateAppStorages, skip, (err, total) ->
        console.log "ERROR >>", err  if err?
        console.log "FINAL #{total}"
        process.exit 0
