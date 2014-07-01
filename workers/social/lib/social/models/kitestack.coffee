{ Model, signature, secure } = require 'bongo'

module.exports = class JKiteStack extends Model

  @share()

  @set
    sharedMethods   :
      static        :
        fetchInfo   : (signature Function)
        setInfo     : (signature Object, Function)
    schema          :
      ratio         : Number
      isEnabled     : Boolean
      useWebSockets :
        type        : Boolean
        default     : true

  @fetchInfo = (callback) ->
    @one {}, (err, info) ->
      return callback err         if err?
      return callback null, info  if info?

      info = new JKiteStack
        ratio     : 0
        isEnabled : yes
      info.save (err) ->
        return callback err  if err

        callback null, info

  @setInfo = secure (client, { ratio, isEnabled, useWebSockets }, callback) ->
    { connection:{ delegate }} = client

    if delegate.can 'flag'
      modifier = $set: {}

      modifier.$set.ratio         = ratio           if ratio?
      modifier.$set.isEnabled     = isEnabled       if isEnabled?
      modifier.$set.useWebSockets = useWebSockets   if useWebSockets?

      @getCollection().update {}, modifier, upsert: yes, (err) -> callback err
    else
      callback message: "Access denied!"
