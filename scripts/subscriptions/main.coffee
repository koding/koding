#!/usr/bin/env coffee
assert  = require 'assert'
mongo   = require 'mongodb'
{argv}  = require 'optimist'

assert argv.c?

KONFIG = require('koding-config-manager').load("main.#{argv.c}")

created = 0

run = (fn) ->
  mongo.MongoClient.connect "mongodb://#{KONFIG.mongo}", (err, db)->
    throw err  if err?

    fn db

createFreeSubscription = ({db, cursor, plan, account}, cb) ->
  {planCode, quantities, tags} = plan
  subscription = 
    planCode   : planCode
    quantity   : 1
    status     : "active"
    feeAmount  : 0
    quantities : quantities
    tags       : tags
    usage      : []

  (db.collection 'jPaymentSubscriptions').insert subscription, (err, [subscription])->
    return cb err if err
    relationship = 
      sourceId   : account._id
      sourceName : "JAccount"
      targetId   : subscription._id
      targetName : "JPaymentSubscription"
      as         : "service subscription"
    (db.collection 'relationships').insert relationship, (err) ->
      return cb err  if err
      created++
      addSubscription {db, cursor, plan}, cb

addSubscription = ({db, cursor, plan}, cb) ->
  console.log '.'
  cursor.nextObject (err, account) ->
    throw err  if err
    return cb null  unless account

    # console.log 'updating', account._id
    (db.collection 'relationships').find(
      sourceId   : account._id
      targetName : "JPaymentSubscription"
      as         : "service subscription"
    ,["targetId"]).toArray (err, rels) ->
      return cb err  if err
      return createFreeSubscription {db, cursor, plan, account}, cb  unless rels.length
      ids = rels.map (rel) ->
        rel.targetId
      selector = 
        _id: $in : ids
        tags    : "nosync"
      (db.collection 'jPaymentSubscriptions').findOne selector, (err, subscription) ->
        return cb err  if err
        return createFreeSubscription {db, cursor, plan, account}, cb  unless subscription
        # console.log 'free subscription already exists'
        addSubscription {db, cursor, plan}, cb

run (db) ->
  console.time 'Free Subscription'
  (db.collection 'jPaymentPlans').findOne tags: "nosync", (err, plan) ->
    return console.error err  if err
    unless plan
      console.error "Free Subscription Plan not found"  
      db.close()
      return process.exit()

    console.log 'Starting Free Subcription Creation'
    cursor = (db.collection 'jAccounts').find {type: "registered"}, ["_id"], {}

    addSubscription {db, cursor, plan}, (err) ->
      console.error err  if err
      console.log "Migration ended with #{created} created free subscriptions"
      console.timeEnd 'Free Subscription'
      db.close()
      process.exit()
