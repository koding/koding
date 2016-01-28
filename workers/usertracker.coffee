{ argv } = require 'optimist'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")

registeredUsers = {}
allUsers = {}

redisClient = null

sendData = (prefix, keys) ->
  dateObj = new Date()
  month = dateObj.getUTCMonth() + 1
  day   = dateObj.getUTCDate()
  year  = dateObj.getUTCFullYear()

  hllDailyKey = "#{prefix}_visitingusers:#{argv.c}:daily:#{year}:#{month}:#{day}"
  redisClient?.pfadd hllDailyKey, keys..., ->

publishToRedis = ->
  uniqueKeysRegistered = Object.keys registeredUsers
  uniqueKeysAll = Object.keys allUsers

  # return if we dont have any registeredUsers for this iteration
  if uniqueKeysRegistered.length > 0
    # clear the previous ones
    registeredUsers = {}
    sendData 'registered', uniqueKeysRegistered

  if uniqueKeysAll.length > 0
    # clear the previous ones
    allUsers = {}
    sendData 'all', uniqueKeysAll

module.exports.track = (username) ->
  # if user is a registered one track them seperately
  registeredUsers[username] = ''  unless /guest-/.test username

  allUsers[username] = ''

module.exports.start = (redisClientInstance) ->
  redisClient = redisClientInstance

  redisClient.on 'error', (err) -> console.log 'redis err', err
  redisClient.on 'connect', -> console.log 'connected to redis'

  setInterval publishToRedis, 10000
