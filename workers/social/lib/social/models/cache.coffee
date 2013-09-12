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
          callback(err)

    @get: (key, callback)->
      JCache.one {key: key}, (err, jc)->
        if jc
          timediff = Math.abs(Date.now() - jc.createdAt) / 1000
          console.log "timediff", timediff
          if timediff > 2
            return callback null, null
        callback err, jc
