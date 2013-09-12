{Model} = require 'bongo'

class MongoCache
  @add: (key, value, callback)->
    JCache.one {key: key}, (err, jc)->
      if err or not jc      
        jc = new JCache()
      jc.key = key
      jc.value = JSON.stringify value
      jc.createdAt = Date.now()
      jc.save (err)->
        if callback
          callback(err)

  @get: (key, callback)->
    JCache.one {key: key}, (err, jc)->
      if jc
        timediff = Math.abs(Date.now() - jc.createdAt) / 1000
        if timediff < 2000000
          return callback null, JSON.parse(jc.value)
      callback null, null

class ProcessCache
  @cache = {}

  @add: (key, value, callback)->
    ProcessCache.cache[key] = {value: value, ts: Date.now()}

  @get: (key, callback)->
    jc = ProcessCache.cache[key]
    if jc
      timediff = Math.abs(Date.now() - jc.ts) / 1000
      console.log timediff
      if timediff < 200000
        return callback null, jc.value
      else
        delete ProcessCache.cache[key]
    callback null, null

module.exports = class JCache extends Model
    
    @cacher: ProcessCache

    @set
      schema           :
        createdAt      :
          type         : Date
          default      : -> new Date
        key:
          type         : String          
        value           :
          type         : String

    @add: (key, value, callback)->
      @cacher.add key, value, callback

    # Usage:
    #   JCache.get "foo", (err, value)->
    #      console.log value if value
    @get: (key, callback)->
      @cacher.get key, callback
