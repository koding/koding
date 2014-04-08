#!/usr/bin/env coffee
assert  = require 'assert'
mongo   = require 'mongodb'
{argv}  = require 'optimist'
{ v4: createId } = require 'node-uuid'

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
    usage      : {}

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

migrateFreeSubscription = (db) ->
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

insertKite = (db, callback) ->
  (db.collection 'jKites').findOne name : "Developer Plan Kite", (err, kite) ->
    return callback err  if err
    return callback null, kite._id  if kite

    kite =
      createdAt   : new Date
      name        : "Developer Plan Kite"
      description : "Developer Plan Kite"
      kiteCode    : createId()

    (db.collection 'jKites').insert kite, (err, [kite]) ->
      return callback err  if err
      callback null, kite._id

addKiteRelationship = ({db, cursor, kiteId}) ->
  cursor.nextObject (err, plan) ->
    throw err  if err
    unless plan
      console.log 'all plans added'
      db.close()
      process.exit()

    relationship =
      sourceId   : plan._id
      sourceName : 'JPaymentPlan'
      as         : 'developerKite'
      targetId   : kiteId
      targetName : 'JKite'

    (db.collection 'relationships').insert relationship, (err) ->
      return  console.error err  if err
      addKiteRelationship {db, cursor, kiteId}


migrateDeveloperPlanKites = (db) ->
  console.time 'Developer Plan'
  insertKite db, (err, kiteId) ->
    return handleError err  if err
    console.log 'kite id', kiteId
    cursor = (db.collection 'jPaymentPlans').find tags: $in: ["rp1", "rp2", "rp3", "rp4", "rp5"], ["_id"]
    addKiteRelationship {db, cursor, kiteId}



handleError = (db, err) ->
  console.error err
  db.close()
  process.exit()

run (db) ->
  switch argv.t
    when "kite"
      migrateDeveloperPlanKites db
    when "freeSubscription"
      migrateFreeSubscription db
    else
      handleError db, "Unkown type parameter. Usage -t <kite|freeSubscription>"

