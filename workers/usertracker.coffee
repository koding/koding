{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

users = {}
redisClient = null

publishToRedis = ->
  uniqueKeys = Object.keys users
  console.log uniqueKeys
  # return if we dont have any users for this iteration
  return if uniqueKeys.length is 0

  # clear the previous ones
  users = {}

  dateObj = new Date()
  month = dateObj.getUTCMonth() + 1
  day   = dateObj.getUTCDate()
  year  = dateObj.getUTCFullYear()

  hllDailyKey = "dailyusers:#{argv.c}:#{year}:#{month}:#{day}"

  redisClient?.pfadd hllDailyKey, uniqueKeys..., ->

module.exports.track = (username)-> users[username] = ""
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
