
Bongo              = require 'bongo'
{ Relationship }   = require 'jraphical'
{ join: joinPath } = require 'path'

KONFIG    = require 'koding-config-manager'
mongo     = "mongodb://#{KONFIG.mongo}"
modelPath = '../../workers/social/lib/social/models'
rekuire   = (p) -> require joinPath modelPath, p

koding = new Bongo
  root   : __dirname
  mongo  : mongo
  models : modelPath

console.log "Trying to connect #{mongo} ..."

koding.once 'dbClientReady', ->

  # rekuire your models here like;
  JAccount    = rekuire 'account.coffee'
  JUser       = rekuire 'user/index.coffee'


  # Config
  # ------

  skip  = 0

  # cache for accounts
  userCache = {}


  # Helpers
  # -------

  # use this to log error on provided index of item
  logError = (err, index) ->
    console.log "ERROR on #{index}. >", err  if err?

  # this is an iterator to use on given mongo cursor
  # you must provide a cursor and a function to pass the obj
  # in that cursor, and an index to start from
  iterate = (cursor, func, index, callback) ->
    cursor.nextObject (err, obj) ->
      if err
        callback err, index
      else if obj?
        func obj, index, (err) ->
          index++
          iterate cursor, func, index, callback
      else
        callback null, index

  # fetches the JAccount and JUser of given JAccount.id
  # provides an in memory cache as well
  fetchAccount = (_id, cb) ->

    if cached = userCache[_id]
      return cb null, cached

    JAccount.one { _id }, (err, account) ->
      return cb err  if err
      return cb { message: 'no account found' }  unless account
      userCache[_id] = { account }
      cb null, userCache[_id]



  # Main updater
  # ------------

  # fetch some data and start ~ for more example check history of this file ~GG

  console.log 'Updater completed.'
