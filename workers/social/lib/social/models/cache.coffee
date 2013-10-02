{Model} = require 'bongo'

class ProcessCache
  @cache = {}
  @cacheTimeout = 20

  @add: (key, value, callback)->
    ProcessCache.cache[key] = {value: value, ts: Date.now()}

  @get: (key, callback)->
    jc = ProcessCache.cache[key]
    if jc
      timediff = Math.abs(Date.now() - jc.ts) / 1000
      if timediff < ProcessCache.cacheTimeout
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
