{Model} = require 'bongo'

module.exports = class JCache extends Model
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
      JCache.one {key: key}, (err, jc)->
        console.log "!!!!!! - ",jc
        if err or not jc      
          jc = new JCache()
        jc.key = key
        jc.value = value
        jc.createdAt = Date.now()
        jc.save (err)->
          console.log ">>>", err
          if callback
            callback(err)

    # Usage:
    #   JCache.get "foo", (err, value)->
    #      console.log value if value
    @get: (key, callback)->
      JCache.one {key: key}, (err, jc)->
        if jc
          timediff = Math.abs(Date.now() - jc.createdAt) / 1000
          console.log "timediff", timediff
          if timediff < 2000000
            console.log "coming from cache !!!!"
            return callback null, JSON.parse(jc.value)
        callback err, null
