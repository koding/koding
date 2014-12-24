{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

registeredUsers = {}
allUsers = {}

redisClient = null

publishToRedis = ->
  uniqueKeysRegistered = Object.keys registeredUsers
  uniqueKeysAll = Object.keys allUsers

  dateObj = new Date()
  month = dateObj.getUTCMonth() + 1
  day   = dateObj.getUTCDate()
  year  = dateObj.getUTCFullYear()

  # return if we dont have any registeredUsers for this iteration
  if uniqueKeysRegistered.length > 0
    # clear the previous ones
    registeredUsers = {}

    hllDailyKey = "registered_visitingusers:#{argv.c}:daily:#{year}:#{month}:#{day}"

    redisClient?.pfadd hllDailyKey, uniqueKeysRegistered..., ->

  if uniqueKeysAll.length > 0
    # clear the previous ones
    allUsers = {}

    hllDailyKey = "all_visitingusers:#{argv.c}:daily:#{year}:#{month}:#{day}"

    redisClient?.pfadd hllDailyKey, uniqueKeysAll..., ->


module.exports.track = (username)->
  # if user is a registered one track them seperately
  registeredUsers[username] = ""  unless /guest-/.test username

  allUsers[username] = ""

module.exports.start = ->
  redis = require "redis"
  redisClient = redis.createClient(
    KONFIG.redis.split(":")[1]
    KONFIG.redis.split(":")[0]
    {}
  )

  redisClient.on "error", (err)-> console.log "redis err", err
  redisClient.on "connect", -> console.log "connected to redis"

  setInterval publishToRedis, 10000
